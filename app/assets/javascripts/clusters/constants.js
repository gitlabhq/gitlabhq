// These need to match the enum found in app/models/clusters/cluster.rb
export const CLUSTER_TYPE = {
  INSTANCE: 'instance_type',
  GROUP: 'group_type',
  PROJECT: 'project_type',
};

// These need to match what is returned from the server
export const APPLICATION_STATUS = {
  NOT_INSTALLABLE: 'not_installable',
  INSTALLABLE: 'installable',
  SCHEDULED: 'scheduled',
  INSTALLING: 'installing',
  INSTALLED: 'installed',
  UPDATED: 'updated',
  UPDATING: 'updating',
  ERROR: 'errored',
};

// These are only used client-side
export const REQUEST_SUBMITTED = 'request-submitted';
export const REQUEST_FAILURE = 'request-failure';
export const INGRESS = 'ingress';
export const JUPYTER = 'jupyter';
export const KNATIVE = 'knative';
export const CERT_MANAGER = 'cert_manager';
