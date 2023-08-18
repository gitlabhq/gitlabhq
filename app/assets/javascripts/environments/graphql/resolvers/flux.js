import axios from '~/lib/utils/axios_utils';
import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';

const helmReleasesApiVersion = 'helm.toolkit.fluxcd.io/v2beta1';
const kustomizationsApiVersion = 'kustomize.toolkit.fluxcd.io/v1beta1';

const handleClusterError = (err) => {
  const error = err?.response?.data?.message ? new Error(err.response.data.message) : err;
  throw error;
};

const buildFluxResourceUrl = ({
  basePath,
  namespace,
  apiVersion,
  resourceType,
  environmentName = '',
}) => {
  return `${basePath}/apis/${apiVersion}/namespaces/${namespace}/${resourceType}/${environmentName}`;
};

const getFluxResourceStatus = (configuration, url) => {
  const { headers } = configuration.baseOptions;
  const withCredentials = true;

  return axios
    .get(url, { withCredentials, headers })
    .then((res) => {
      return res?.data?.status?.conditions || [];
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

const getFluxResources = (configuration, url) => {
  const { headers } = configuration.baseOptions;
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

export default {
  fluxKustomizationStatus(_, { configuration, namespace, environmentName, fluxResourcePath = '' }) {
    let url;

    if (fluxResourcePath) {
      url = `${configuration.basePath}/apis/${fluxResourcePath}`;
    } else {
      url = buildFluxResourceUrl({
        basePath: configuration.basePath,
        resourceType: KUSTOMIZATIONS_RESOURCE_TYPE,
        apiVersion: kustomizationsApiVersion,
        namespace,
        environmentName,
      });
    }
    return getFluxResourceStatus(configuration, url);
  },
  fluxHelmReleaseStatus(_, { configuration, namespace, environmentName, fluxResourcePath }) {
    let url;

    if (fluxResourcePath) {
      url = `${configuration.basePath}/apis/${fluxResourcePath}`;
    } else {
      url = buildFluxResourceUrl({
        basePath: configuration.basePath,
        resourceType: HELM_RELEASES_RESOURCE_TYPE,
        apiVersion: helmReleasesApiVersion,
        namespace,
        environmentName,
      });
    }
    return getFluxResourceStatus(configuration, url);
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
