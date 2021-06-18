// These need to match the enum found in app/models/clusters/cluster.rb
export const CLUSTER_TYPE = {
  INSTANCE: 'instance_type',
  GROUP: 'group_type',
  PROJECT: 'project_type',
};

// These need to match the available providers in app/models/clusters/providers/
export const PROVIDER_TYPE = {
  GCP: 'gcp',
};

// These are only used client-side

export const LOGGING_MODE = 'logging';
export const BLOCKING_MODE = 'blocking';
