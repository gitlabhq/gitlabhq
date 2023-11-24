import {
  CoreV1Api,
  Configuration,
  AppsV1Api,
  BatchV1Api,
  WatchApi,
  EVENT_DATA,
} from '@gitlab/cluster-client';
import produce from 'immer';
import {
  getK8sPods,
  handleClusterError,
} from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import { humanizeClusterErrors } from '../../helpers/k8s_integration_helper';
import k8sPodsQuery from '../queries/k8s_pods.query.graphql';
import k8sWorkloadsQuery from '../queries/k8s_workloads.query.graphql';
import k8sServicesQuery from '../queries/k8s_services.query.graphql';

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

const watchWorkloadItems = ({ kind, apiVersion, configuration, namespace, client }) => {
  const itemKind = kind.toLowerCase().replace('list', 's');

  const path = namespace
    ? `/apis/${apiVersion}/namespaces/${namespace}/${itemKind}`
    : `/apis/${apiVersion}/${itemKind}`;
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  watcherApi
    .subscribeToStream(path, { watch: true })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = mapWorkloadItems(data, kind);

        const sourceData = client.readQuery({
          query: k8sWorkloadsQuery,
          variables: { configuration, namespace },
        });

        const updatedData = produce(sourceData, (draft) => {
          draft.k8sWorkloads[kind] = result;
        });

        client.writeQuery({
          query: k8sWorkloadsQuery,
          variables: { configuration, namespace },
          data: updatedData,
        });
      });
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

const mapServicesItems = (items) => {
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
};

const watchServices = ({ configuration, namespace, client }) => {
  const path = namespace ? `/api/v1/namespaces/${namespace}/services` : '/api/v1/services';
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  watcherApi
    .subscribeToStream(path, { watch: true })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = mapServicesItems(data);

        client.writeQuery({
          query: k8sServicesQuery,
          variables: { configuration, namespace },
          data: { k8sServices: result },
        });
      });
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

export default {
  k8sPods(_, { configuration, namespace }, { client }) {
    const query = k8sPodsQuery;
    const enableWatch = gon.features?.k8sWatchApi;
    return getK8sPods({ client, query, configuration, namespace, enableWatch });
  },
  k8sServices(_, { configuration, namespace }, { client }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const servicesApi = namespace
      ? coreV1Api.listCoreV1NamespacedService({ namespace })
      : coreV1Api.listCoreV1ServiceForAllNamespaces();

    return servicesApi
      .then((res) => {
        const items = res?.items || [];

        if (gon.features?.k8sWatchApi) {
          watchServices({ configuration, namespace, client });
        }

        return mapServicesItems(items);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },
  k8sWorkloads(_, { configuration, namespace }, { client }) {
    const appsV1api = new AppsV1Api(new Configuration(configuration));
    const batchV1api = new BatchV1Api(new Configuration(configuration));

    let promises;

    if (namespace) {
      promises = [
        appsV1api.listAppsV1NamespacedDeployment({ namespace }),
        appsV1api.listAppsV1NamespacedDaemonSet({ namespace }),
        appsV1api.listAppsV1NamespacedStatefulSet({ namespace }),
        appsV1api.listAppsV1NamespacedReplicaSet({ namespace }),
        batchV1api.listBatchV1NamespacedJob({ namespace }),
        batchV1api.listBatchV1NamespacedCronJob({ namespace }),
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

    return Promise.allSettled(promises).then(async (results) => {
      if (results.every((res) => res.status === 'rejected')) {
        const error = results[0].reason;
        try {
          await handleClusterError(error);
        } catch (err) {
          throw new Error(err.message);
        }
      }
      for (const promiseResult of results) {
        if (promiseResult.status === 'fulfilled' && promiseResult?.value) {
          const { kind, items, apiVersion } = promiseResult.value;

          if (items?.length > 0) {
            summaryList[kind] = mapWorkloadItems(items, kind);

            watchWorkloadItems({ kind, apiVersion, configuration, namespace, client });
          }
        }
      }

      return summaryList;
    });
  },
  k8sNamespaces(_, { configuration }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const namespacesApi = coreV1Api.listCoreV1Namespace();

    return namespacesApi
      .then((res) => {
        return res?.items || [];
      })
      .catch(async (error) => {
        try {
          await handleClusterError(error);
        } catch (err) {
          throw new Error(humanizeClusterErrors(err.reason));
        }
      });
  },
};
