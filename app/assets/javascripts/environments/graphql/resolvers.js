import { CoreV1Api, Configuration } from '@gitlab/cluster-client';
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
