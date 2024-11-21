import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const usageQuotasHelpPaths = {
  repositorySizeLimit: helpPagePath('administration/settings/account_and_limit_settings', {
    anchor: 'repository-size-limit',
  }),
  usageQuotas: helpPagePath('user/storage_usage_quotas'),
  usageQuotasProjectStorageLimit: helpPagePath('user/storage_usage_quotas', {
    anchor: 'view-storage',
  }),
  usageQuotasNamespaceStorageLimit: helpPagePath('user/storage_usage_quotas', {
    anchor: 'view-storage',
  }),
};

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'buildArtifacts',
    name: __('Job artifacts'),
    description: s__('UsageQuota|Job artifacts created by CI/CD.'),
  },
  {
    id: 'lfsObjects',
    name: __('LFS'),
    description: s__('UsageQuota|Audio samples, videos, datasets, and graphics.'),
  },
  {
    id: 'packages',
    name: __('Packages'),
    description: s__('UsageQuota|Code packages and container images.'),
  },
  {
    id: 'repository',
    name: __('Repository'),
    description: s__('UsageQuota|Git repository.'),
  },
  {
    id: 'snippets',
    name: __('Snippets'),
    description: s__('UsageQuota|Shared bits of code and text.'),
  },
  {
    id: 'wiki',
    name: __('Wiki'),
    description: s__('UsageQuota|Wiki content.'),
  },
];

export const NAMESPACE_STORAGE_TYPES = [
  {
    id: 'containerRegistry',
    name: __('Container Registry'),
    description: s__(
      `UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.`,
    ),
    warning: {
      popoverContent: s__(
        'UsageQuotas|Container Registry storage statistics are not used to calculate the total project storage. Total project storage is calculated after namespace container deduplication, where the total of all unique containers is added to the namespace storage total.',
      ),
    },
  },
];

export const storageTypeHelpPaths = {
  lfsObjects: helpPagePath('/user/project/repository/repository_size', {
    anchor: 'clean-up-repository',
  }),
  containerRegistry: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
  ),
  buildArtifacts: helpPagePath('ci/jobs/job_artifacts', {
    anchor: 'keep-artifacts-from-most-recent-successful-jobs',
  }),
  packages: helpPagePath('user/packages/package_registry/index.md', {
    anchor: 'reduce-storage-usage',
  }),
  repository: helpPagePath('user/project/repository/repository_size'),
  snippets: helpPagePath('user/snippets', {
    anchor: 'reduce-snippets-repository-size',
  }),
  wiki: helpPagePath('administration/wikis/index.md', {
    anchor: 'reduce-wiki-repository-size',
  }),
};
