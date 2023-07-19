import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching project storage statistics',
);
export const LEARN_MORE_LABEL = __('Learn more.');
export const USAGE_QUOTAS_LABEL = s__('UsageQuota|Usage Quotas');
export const TOTAL_USAGE_TITLE = s__('UsageQuota|Usage breakdown');
export const TOTAL_USAGE_SUBTITLE = s__(
  'UsageQuota|Includes artifacts, repositories, wiki, and other items.',
);
export const TOTAL_USAGE_DEFAULT_TEXT = __('Not applicable.');
export const HELP_LINK_ARIA_LABEL = s__('UsageQuota|%{linkTitle} help link');
export const RECALCULATE_REPOSITORY_LABEL = s__('UsageQuota|Recalculate repository usage');

export const projectContainerRegistryPopoverContent = s__(
  'UsageQuotas|The project-level storage statistics for the Container Registry are directional only and do not include savings for instance-wide deduplication.',
);

export const containerRegistryId = 'containerRegistrySize';
export const containerRegistryPopoverId = 'container-registry-popover';

export const PROJECT_TABLE_LABEL_STORAGE_TYPE = s__('UsageQuota|Storage type');
export const PROJECT_TABLE_LABEL_USAGE = s__('UsageQuota|Usage');

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'containerRegistry',
    name: __('Container Registry'),
    description: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
    ),
  },
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

export const projectHelpPaths = {
  usageQuotas: helpPagePath('user/usage_quotas'),
  usageQuotasProjectStorageLimit: helpPagePath('user/usage_quotas', {
    anchor: 'project-storage-limit',
  }),
  usageQuotasNamespaceStorageLimit: helpPagePath('user/usage_quotas', {
    anchor: 'namespace-storage-limit',
  }),
  lfsObjects: helpPagePath('/user/project/repository/reducing_the_repo_size_using_git', {
    anchor: 'repository-cleanup',
  }),
  containerRegistry: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
  ),
  buildArtifacts: helpPagePath('ci/pipelines/job_artifacts', {
    anchor: 'when-job-artifacts-are-deleted',
  }),
  packages: helpPagePath('user/packages/package_registry/index.md', {
    anchor: 'reduce-storage-usage',
  }),
  repository: helpPagePath('user/project/repository/reducing_the_repo_size_using_git'),
  snippets: helpPagePath('user/snippets', {
    anchor: 'reduce-snippets-repository-size',
  }),
  wiki: helpPagePath('administration/wikis/index.md', {
    anchor: 'reduce-wiki-repository-size',
  }),
};
