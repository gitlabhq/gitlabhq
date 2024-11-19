import { Configuration, WatchApi, EVENT_DATA, EVENT_TIMEOUT } from '@gitlab/cluster-client';
import axios from '~/lib/utils/axios_utils';
import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';
import { subscribeToSocket } from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';
import { buildKubernetesErrors } from '~/environments/helpers/k8s_integration_helper';
import fluxKustomizationQuery from '../queries/flux_kustomization.query.graphql';
import fluxHelmReleaseQuery from '../queries/flux_helm_release.query.graphql';

const helmReleasesApiVersion = 'helm.toolkit.fluxcd.io/v2beta1';
const kustomizationsApiVersion = 'kustomize.toolkit.fluxcd.io/v1';

const helmReleaseField = 'fluxHelmRelease';
const kustomizationField = 'fluxKustomization';

const handleClusterError = (err) => {
  const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
  throw error;
};

const buildFluxResourceUrl = ({ basePath, namespace, apiVersion, resourceType }) => {
  return `${basePath}/apis/${apiVersion}/namespaces/${namespace}/${resourceType}`;
};

export const buildFluxResourceWatchPath = ({ namespace, apiVersion, resourceType }) => {
  return `/apis/${apiVersion}/namespaces/${namespace}/${resourceType}`;
};

const mapFluxItems = (fluxItem, resourceType) => {
  const metadata = {
    ...fluxItem.metadata,
    annotations: fluxItem.metadata?.annotations || {},
    labels: fluxItem.metadata?.labels || {},
  };

  const result = {
    kind: fluxItem?.kind || '',
    status: fluxItem.status || {},
    spec: fluxItem.spec || {},
    metadata,
    conditions: fluxItem.status?.conditions || [],
    __typename: 'LocalWorkloadItem',
  };

  if (resourceType === KUSTOMIZATIONS_RESOURCE_TYPE) {
    result.inventory = fluxItem.status?.inventory?.entries || [];
  }
  return result;
};

const watchFluxResource = async ({
  apiVersion,
  resourceName,
  namespace,
  query,
  variables,
  resourceType,
  field,
  client,
}) => {
  const watchPath = buildFluxResourceWatchPath({ namespace, apiVersion, resourceType });
  const fieldSelector = `metadata.name=${decodeURIComponent(resourceName)}`;

  const updateFluxConnection = (status) => {
    updateConnectionStatus(client, {
      configuration: variables.configuration,
      namespace,
      resourceType,
      status,
    });
  };

  const updateQueryCache = (data) => {
    const result = mapFluxItems(data[0], resourceType);
    client.writeQuery({
      query,
      variables,
      data: { [field]: result },
    });
  };

  const watchFunction = async () => {
    const config = new Configuration(variables.configuration);
    const watcherApi = new WatchApi(config);

    try {
      const watcher = await watcherApi.subscribeToStream(watchPath, { watch: true, fieldSelector });
      watcher.on(EVENT_DATA, (data) => {
        updateQueryCache(data);
        updateFluxConnection(connectionStatus.connected);
      });
      watcher.on(EVENT_TIMEOUT, () => updateFluxConnection(connectionStatus.disconnected));
    } catch (err) {
      await handleClusterError(err);
    }
  };

  updateFluxConnection(connectionStatus.connecting);

  if (gon?.features?.useWebsocketForK8sWatch) {
    const watchId = `${resourceType}-${resourceName}`;
    const [group, version] = apiVersion.split('/');
    const watchParams = {
      version,
      group,
      resource: resourceType,
      fieldSelector,
      namespace,
    };
    const cacheParams = {
      updateQueryCache,
      updateConnectionStatusFn: updateFluxConnection,
    };

    try {
      await subscribeToSocket({
        watchId,
        watchParams,
        configuration: variables.configuration,
        cacheParams,
      });
    } catch {
      await watchFunction();
    }
  } else {
    await watchFunction();
  }
};

const getFluxResource = ({ query, variables, field, resourceType, client }) => {
  const { headers } = variables.configuration;
  const withCredentials = true;
  const url = `${variables.configuration.basePath}/apis/${variables.fluxResourcePath}`;

  return axios
    .get(url, { withCredentials, headers })
    .then((res) => {
      const fluxData = res?.data;
      const resourceName = fluxData?.metadata?.name;
      const namespace = fluxData?.metadata?.namespace;
      const apiVersion = fluxData?.apiVersion;

      if (resourceName) {
        watchFluxResource({
          apiVersion,
          resourceName,
          namespace,
          query,
          variables,
          resourceType,
          field,
          client,
        });
      }

      return mapFluxItems(fluxData, resourceType);
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

export const watchFluxKustomization = ({ configuration, client, fluxResourcePath }) => {
  const query = fluxKustomizationQuery;
  const variables = { configuration, fluxResourcePath };
  const field = kustomizationField;
  const resourceType = KUSTOMIZATIONS_RESOURCE_TYPE;

  getFluxResource({ query, variables, field, resourceType, client });
};

export const watchFluxHelmRelease = ({ configuration, client, fluxResourcePath }) => {
  const query = fluxHelmReleaseQuery;
  const variables = { configuration, fluxResourcePath };
  const field = helmReleaseField;
  const resourceType = HELM_RELEASES_RESOURCE_TYPE;

  getFluxResource({ query, variables, field, resourceType, client });
};

const getFluxResources = (configuration, url) => {
  const { headers } = configuration;
  const withCredentials = true;

  return axios
    .get(url, { withCredentials, headers })
    .then((res) => {
      const items = res?.data?.items || [];
      const result = items.map((item) => {
        return {
          apiVersion: item.apiVersion,
          metadata: {
            name: item.metadata?.name,
            namespace: item.metadata?.namespace,
          },
        };
      });
      return result || [];
    })
    .catch((err) => {
      const error = err?.response?.data?.reason || err;
      throw new Error(error);
    });
};

export const fluxMutations = {
  updateFluxResource(_, { configuration, fluxResourcePath, data }) {
    const headers = {
      ...configuration.headers,
      'Content-Type': 'application/json-patch+json',
    };
    const withCredentials = true;
    const url = `${configuration.basePath}/apis/${fluxResourcePath}`;

    return axios
      .patch(url, data, { withCredentials, headers })
      .then(() => {
        return buildKubernetesErrors();
      })
      .catch((err) => {
        const error = err?.response?.data?.message || err;
        return buildKubernetesErrors([error]);
      });
  },
};

export const fluxQueries = {
  fluxKustomization(_, { configuration, fluxResourcePath }, { client }) {
    return getFluxResource({
      query: fluxKustomizationQuery,
      variables: { configuration, fluxResourcePath },
      field: kustomizationField,
      resourceType: KUSTOMIZATIONS_RESOURCE_TYPE,
      client,
    });
  },
  fluxHelmRelease(_, { configuration, fluxResourcePath }, { client }) {
    return getFluxResource({
      query: fluxHelmReleaseQuery,
      variables: { configuration, fluxResourcePath },
      field: helmReleaseField,
      resourceType: HELM_RELEASES_RESOURCE_TYPE,
      client,
    });
  },
  fluxKustomizations(_, { configuration, namespace }) {
    const url = buildFluxResourceUrl({
      basePath: configuration.basePath,
      resourceType: KUSTOMIZATIONS_RESOURCE_TYPE,
      apiVersion: kustomizationsApiVersion,
      namespace,
    });
    return getFluxResources(configuration, url);
  },
  fluxHelmReleases(_, { configuration, namespace }) {
    const url = buildFluxResourceUrl({
      basePath: configuration.basePath,
      resourceType: HELM_RELEASES_RESOURCE_TYPE,
      apiVersion: helmReleasesApiVersion,
      namespace,
    });
    return getFluxResources(configuration, url);
  },
};
