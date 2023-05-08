import { CoreV1Api, Configuration, AppsV1Api, BatchV1Api } from '@gitlab/cluster-client';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import {
  convertObjectPropsToCamelCase,
  parseIntPagination,
  normalizeHeaders,
} from '~/lib/utils/common_utils';

import pollIntervalQuery from './queries/poll_interval.query.graphql';
import environmentToRollbackQuery from './queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from './queries/environment_to_stop.query.graphql';
import environmentToDeleteQuery from './queries/environment_to_delete.query.graphql';
import environmentToChangeCanaryQuery from './queries/environment_to_change_canary.query.graphql';
import isEnvironmentStoppingQuery from './queries/is_environment_stopping.query.graphql';
import pageInfoQuery from './queries/page_info.query.graphql';

const buildErrors = (errors = []) => ({
  errors,
  __typename: 'LocalEnvironmentErrors',
});

const mapNestedEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env, { deep: true }),
  __typename: 'NestedLocalEnvironment',
});
const mapEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env, { deep: true }),
  __typename: 'LocalEnvironment',
});

const mapWorkloadItems = (items, kind) => {
  return items.map((item) => {
    const updatedItem = {
      status: {},
      spec: {},
    };

    switch (kind) {
      case 'DeploymentList':
        updatedItem.status.conditions = item.status.conditions || [];
        break;
      case 'DaemonSetList':
        updatedItem.status = {
          numberMisscheduled: item.status.numberMisscheduled || 0,
          numberReady: item.status.numberReady || 0,
          desiredNumberScheduled: item.status.desiredNumberScheduled || 0,
        };
        break;
      case 'StatefulSetList':
      case 'ReplicaSetList':
        updatedItem.status.readyReplicas = item.status.readyReplicas || 0;
        updatedItem.spec.replicas = item.spec.replicas || 0;
        break;
      case 'JobList':
        updatedItem.status.failed = item.status.failed || 0;
        updatedItem.status.succeeded = item.status.succeeded || 0;
        updatedItem.spec.completions = item.spec.completions || 0;
        break;
      case 'CronJobList':
        updatedItem.status.active = item.status.active || 0;
        updatedItem.status.lastScheduleTime = item.status.lastScheduleTime || '';
        updatedItem.spec.suspend = item.spec.suspend || 0;
        break;
      default:
        updatedItem.status = item?.status;
        updatedItem.spec = item?.spec;
        break;
    }

    return updatedItem;
  });
};

export const resolvers = (endpoint) => ({
  Query: {
    environmentApp(_context, { page, scope, search }, { cache }) {
      return axios.get(endpoint, { params: { nested: true, page, scope, search } }).then((res) => {
        const headers = normalizeHeaders(res.headers);
        const interval = headers['POLL-INTERVAL'];
        const pageInfo = { ...parseIntPagination(headers), __typename: 'LocalPageInfo' };

        if (interval) {
          cache.writeQuery({ query: pollIntervalQuery, data: { interval: parseFloat(interval) } });
        } else {
          cache.writeQuery({ query: pollIntervalQuery, data: { interval: undefined } });
        }

        cache.writeQuery({
          query: pageInfoQuery,
          data: { pageInfo },
        });

        return {
          availableCount: res.data.available_count,
          environments: res.data.environments.map(mapNestedEnvironment),
          reviewApp: {
            ...convertObjectPropsToCamelCase(res.data.review_app),
            __typename: 'ReviewApp',
          },
          canStopStaleEnvironments: res.data.can_stop_stale_environments,
          stoppedCount: res.data.stopped_count,
          __typename: 'LocalEnvironmentApp',
        };
      });
    },
    folder(_, { environment: { folderPath }, scope, search }) {
      return axios.get(folderPath, { params: { scope, search, per_page: 3 } }).then((res) => ({
        availableCount: res.data.available_count,
        environments: res.data.environments.map(mapEnvironment),
        stoppedCount: res.data.stopped_count,
        __typename: 'LocalEnvironmentFolder',
      }));
    },
    isLastDeployment(_, { environment }) {
      return environment?.lastDeployment?.isLast;
    },
    k8sPods(_, { configuration, namespace }) {
      const coreV1Api = new CoreV1Api(new Configuration(configuration));
      const podsApi = namespace
        ? coreV1Api.listCoreV1NamespacedPod(namespace)
        : coreV1Api.listCoreV1PodForAllNamespaces();

      return podsApi
        .then((res) => res?.data?.items || [])
        .catch((err) => {
          const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
          throw error;
        });
    },
    k8sServices(_, { configuration }) {
      const coreV1Api = new CoreV1Api(new Configuration(configuration));
      return coreV1Api
        .listCoreV1ServiceForAllNamespaces()
        .then((res) => {
          const items = res?.data?.items || [];
          return items.map((item) => {
            const { type, clusterIP, externalIP, ports } = item.spec;
            return {
              metadata: item.metadata,
              spec: {
                type,
                clusterIP: clusterIP || '-',
                externalIP: externalIP || '-',
                ports,
              },
            };
          });
        })
        .catch((err) => {
          const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
          throw error;
        });
    },
    k8sWorkloads(_, { configuration, namespace }) {
      const appsV1api = new AppsV1Api(configuration);
      const batchV1api = new BatchV1Api(configuration);

      let promises;

      if (namespace) {
        promises = [
          appsV1api.listAppsV1NamespacedDeployment(namespace),
          appsV1api.listAppsV1NamespacedDaemonSet(namespace),
          appsV1api.listAppsV1NamespacedStatefulSet(namespace),
          appsV1api.listAppsV1NamespacedReplicaSet(namespace),
          batchV1api.listBatchV1NamespacedJob(namespace),
          batchV1api.listBatchV1NamespacedCronJob(namespace),
        ];
      } else {
        promises = [
          appsV1api.listAppsV1DeploymentForAllNamespaces(),
          appsV1api.listAppsV1DaemonSetForAllNamespaces(),
          appsV1api.listAppsV1StatefulSetForAllNamespaces(),
          appsV1api.listAppsV1ReplicaSetForAllNamespaces(),
          batchV1api.listBatchV1JobForAllNamespaces(),
          batchV1api.listBatchV1CronJobForAllNamespaces(),
        ];
      }

      const summaryList = {
        DeploymentList: [],
        DaemonSetList: [],
        StatefulSetList: [],
        ReplicaSetList: [],
        JobList: [],
        CronJobList: [],
      };

      return Promise.allSettled(promises).then((results) => {
        if (results.every((res) => res.status === 'rejected')) {
          const error = results[0].reason;
          const errorMessage = error?.response?.data?.message ?? error;
          throw new Error(errorMessage);
        }
        for (const promiseResult of results) {
          if (promiseResult.status === 'fulfilled' && promiseResult?.value?.data) {
            const { kind, items } = promiseResult.value.data;

            if (items?.length > 0) {
              summaryList[kind] = mapWorkloadItems(items, kind);
            }
          }
        }

        return summaryList;
      });
    },
  },
  Mutation: {
    stopEnvironmentREST(_, { environment }, { client }) {
      client.writeQuery({
        query: isEnvironmentStoppingQuery,
        variables: { environment },
        data: { isEnvironmentStopping: true },
      });
      return axios
        .post(environment.stopPath)
        .then(() => buildErrors())
        .catch(() => {
          client.writeQuery({
            query: isEnvironmentStoppingQuery,
            variables: { environment },
            data: { isEnvironmentStopping: false },
          });
          return buildErrors([
            s__('Environments|An error occurred while stopping the environment, please try again'),
          ]);
        });
    },
    deleteEnvironment(_, { environment: { deletePath } }) {
      return axios
        .delete(deletePath)
        .then(() => buildErrors())
        .catch(() =>
          buildErrors([
            s__(
              'Environments|An error occurred while deleting the environment. Check if the environment stopped; if not, stop it and try again.',
            ),
          ]),
        );
    },
    rollbackEnvironment(_, { environment, isLastDeployment }) {
      return axios
        .post(environment?.retryUrl)
        .then(() => buildErrors())
        .catch(() => {
          buildErrors([
            isLastDeployment
              ? s__(
                  'Environments|An error occurred while re-deploying the environment, please try again',
                )
              : s__(
                  'Environments|An error occurred while rolling back the environment, please try again',
                ),
          ]);
        });
    },
    setEnvironmentToStop(_, { environment }, { client }) {
      client.writeQuery({
        query: environmentToStopQuery,
        data: { environmentToStop: environment },
      });
    },
    action(_, { action: { playPath } }) {
      return axios
        .post(playPath)
        .then(() => buildErrors())
        .catch(() =>
          buildErrors([s__('Environments|An error occurred while making the request.')]),
        );
    },
    setEnvironmentToDelete(_, { environment }, { client }) {
      client.writeQuery({
        query: environmentToDeleteQuery,
        data: { environmentToDelete: environment },
      });
    },
    setEnvironmentToRollback(_, { environment }, { client }) {
      client.writeQuery({
        query: environmentToRollbackQuery,
        data: { environmentToRollback: environment },
      });
    },
    setEnvironmentToChangeCanary(_, { environment, weight }, { client }) {
      client.writeQuery({
        query: environmentToChangeCanaryQuery,
        data: { environmentToChangeCanary: environment, weight },
      });
    },
    cancelAutoStop(_, { autoStopUrl }) {
      return axios
        .post(autoStopUrl)
        .then(() => buildErrors())
        .catch((err) =>
          buildErrors([
            err?.response?.data?.message ||
              s__('Environments|An error occurred while canceling the auto stop, please try again'),
          ]),
        );
    },
  },
});
