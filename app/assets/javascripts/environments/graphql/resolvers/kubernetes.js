import { CoreV1Api, Configuration, AppsV1Api, BatchV1Api } from '@gitlab/cluster-client';
import { humanizeClusterErrors } from '../../helpers/k8s_integration_helper';

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

const handleClusterError = (err) => {
  const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
  throw error;
};

export default {
  k8sPods(_, { configuration, namespace }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const podsApi = namespace
      ? coreV1Api.listCoreV1NamespacedPod(namespace)
      : coreV1Api.listCoreV1PodForAllNamespaces();

    return podsApi
      .then((res) => res?.data?.items || [])
      .catch((err) => {
        handleClusterError(err);
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
        handleClusterError(err);
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
  k8sNamespaces(_, { configuration }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const namespacesApi = coreV1Api.listCoreV1Namespace();

    return namespacesApi
      .then((res) => {
        return res?.data?.items || [];
      })
      .catch((err) => {
        const error = err?.response?.data?.reason || err;
        throw new Error(humanizeClusterErrors(error));
      });
  },
};
