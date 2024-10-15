import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
} from '~/environments/constants';

export const connectionStatus = {
  connected: 'connected',
  disconnected: 'disconnected',
  connecting: 'connecting',
};

export const k8sResourceType = {
  k8sServices: 'k8sServices',
  k8sPods: 'k8sPods',
  k8sDeployments: 'k8sDeployments',
  fluxHelmReleases: HELM_RELEASES_RESOURCE_TYPE,
  fluxKustomizations: KUSTOMIZATIONS_RESOURCE_TYPE,
  k8sEvents: 'k8sEvents',
};
