import { keyBy } from 'lodash';
import { s__, __ } from '~/locale';

export const RESOURCE_CONTAINERS = { value: 'CONTAINERS', text: s__('JobToken|Containers') };
export const RESOURCE_DEPLOYMENTS = { value: 'DEPLOYMENTS', text: s__('JobToken|Deployments') };
export const RESOURCE_ENVIRONMENTS = { value: 'ENVIRONMENTS', text: s__('JobToken|Environments') };
export const RESOURCE_JOBS = { value: 'JOBS', text: s__('JobToken|Jobs') };
export const RESOURCE_PACKAGES = { value: 'PACKAGES', text: s__('JobToken|Packages') };
export const RESOURCE_RELEASES = { value: 'RELEASES', text: s__('JobToken|Releases') };
export const RESOURCE_SECURE_FILES = { value: 'SECURE_FILES', text: s__('JobToken|Secure files') };
export const RESOURCE_TERRAFORM_STATE = {
  value: 'TERRAFORM_STATE',
  text: s__('JobToken|Terraform state'),
};

const READ = s__('JobToken|Read');
const READ_AND_WRITE = s__('JobToken|Read and write');

export const POLICY_READ_CONTAINERS = {
  value: 'READ_CONTAINERS',
  text: READ,
  resource: RESOURCE_CONTAINERS,
};
export const POLICY_ADMIN_CONTAINERS = {
  value: 'ADMIN_CONTAINERS',
  text: READ_AND_WRITE,
  resource: RESOURCE_CONTAINERS,
};
export const POLICY_READ_DEPLOYMENTS = {
  value: 'READ_DEPLOYMENTS',
  text: READ,
  resource: RESOURCE_DEPLOYMENTS,
};
export const POLICY_ADMIN_DEPLOYMENTS = {
  value: 'ADMIN_DEPLOYMENTS',
  text: READ_AND_WRITE,
  resource: RESOURCE_DEPLOYMENTS,
};
export const POLICY_READ_ENVIRONMENTS = {
  value: 'READ_ENVIRONMENTS',
  text: READ,
  resource: RESOURCE_ENVIRONMENTS,
};
export const POLICY_ADMIN_ENVIRONMENTS = {
  value: 'ADMIN_ENVIRONMENTS',
  text: READ_AND_WRITE,
  resource: RESOURCE_ENVIRONMENTS,
};
export const POLICY_READ_JOBS = {
  value: 'READ_JOBS',
  text: READ,
  resource: RESOURCE_JOBS,
};
export const POLICY_ADMIN_JOBS = {
  value: 'ADMIN_JOBS',
  text: READ_AND_WRITE,
  resource: RESOURCE_JOBS,
};
export const POLICY_READ_PACKAGES = {
  value: 'READ_PACKAGES',
  text: READ,
  resource: RESOURCE_PACKAGES,
};
export const POLICY_ADMIN_PACKAGES = {
  value: 'ADMIN_PACKAGES',
  text: READ_AND_WRITE,
  resource: RESOURCE_PACKAGES,
};
export const POLICY_READ_RELEASES = {
  value: 'READ_RELEASES',
  text: READ,
  resource: RESOURCE_RELEASES,
};
export const POLICY_ADMIN_RELEASES = {
  value: 'ADMIN_RELEASES',
  text: READ_AND_WRITE,
  resource: RESOURCE_RELEASES,
};
export const POLICY_READ_SECURE_FILES = {
  value: 'READ_SECURE_FILES',
  text: READ,
  resource: RESOURCE_SECURE_FILES,
};
export const POLICY_ADMIN_SECURE_FILES = {
  value: 'ADMIN_SECURE_FILES',
  text: READ_AND_WRITE,
  resource: RESOURCE_SECURE_FILES,
};
export const POLICY_READ_TERRAFORM_STATE = {
  value: 'READ_TERRAFORM_STATE',
  text: READ,
  resource: RESOURCE_TERRAFORM_STATE,
};
export const POLICY_ADMIN_TERRAFORM_STATE = {
  value: 'ADMIN_TERRAFORM_STATE',
  text: READ_AND_WRITE,
  resource: RESOURCE_TERRAFORM_STATE,
};
export const POLICY_NONE = { value: '', text: __('None') };

export const POLICIES_BY_RESOURCE = [
  {
    resource: RESOURCE_CONTAINERS,
    policies: [POLICY_NONE, POLICY_READ_CONTAINERS, POLICY_ADMIN_CONTAINERS],
  },
  {
    resource: RESOURCE_DEPLOYMENTS,
    policies: [POLICY_NONE, POLICY_READ_DEPLOYMENTS, POLICY_ADMIN_DEPLOYMENTS],
  },
  {
    resource: RESOURCE_ENVIRONMENTS,
    policies: [POLICY_NONE, POLICY_READ_ENVIRONMENTS, POLICY_ADMIN_ENVIRONMENTS],
  },
  {
    resource: RESOURCE_JOBS,
    policies: [POLICY_NONE, POLICY_READ_JOBS, POLICY_ADMIN_JOBS],
  },
  {
    resource: RESOURCE_PACKAGES,
    policies: [POLICY_NONE, POLICY_READ_PACKAGES, POLICY_ADMIN_PACKAGES],
  },
  {
    resource: RESOURCE_RELEASES,
    policies: [POLICY_NONE, POLICY_READ_RELEASES, POLICY_ADMIN_RELEASES],
  },
  {
    resource: RESOURCE_SECURE_FILES,
    policies: [POLICY_NONE, POLICY_READ_SECURE_FILES, POLICY_ADMIN_SECURE_FILES],
  },
  {
    resource: RESOURCE_TERRAFORM_STATE,
    policies: [POLICY_NONE, POLICY_READ_TERRAFORM_STATE, POLICY_ADMIN_TERRAFORM_STATE],
  },
];

// Create an object where the key is the resource value string and the value is the resource object. Used to look up
// a resource by its value string.
export const JOB_TOKEN_RESOURCES = keyBy(
  POLICIES_BY_RESOURCE.map(({ resource }) => resource),
  ({ value }) => value,
);
// Create an object where the key is the policy value string and the value is the policy object. Used to look up a
// policy by its value string.
export const JOB_TOKEN_POLICIES = keyBy(
  POLICIES_BY_RESOURCE.flatMap(({ policies }) => policies),
  ({ value }) => value,
);

export const JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT = 'JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT';
export const JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG = 'JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG';
