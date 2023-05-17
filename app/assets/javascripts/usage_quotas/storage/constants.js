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
    id: 'containerRegistrySize',
    name: __('Container Registry'),
    description: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
    ),
  },
  {
    id: 'buildArtifactsSize',
    name: __('Job artifacts'),
    description: s__('UsageQuota|Job artifacts created by CI/CD.'),
  },
  {
    id: 'pipelineArtifactsSize',
    name: __('Pipeline artifacts'),
    description: s__('UsageQuota|Pipeline artifacts created by CI/CD.'),
  },
  {
    id: 'lfsObjectsSize',
    name: __('LFS'),
    description: s__('UsageQuota|Audio samples, videos, datasets, and graphics.'),
  },
  {
    id: 'packagesSize',
    name: __('Packages'),
    description: s__('UsageQuota|Code packages and container images.'),
  },
  {
    id: 'repositorySize',
    name: __('Repository'),
    description: s__('UsageQuota|Git repository.'),
  },
  {
    id: 'snippetsSize',
    name: __('Snippets'),
    description: s__('UsageQuota|Shared bits of code and text.'),
  },
  {
    id: 'wikiSize',
    name: __('Wiki'),
    description: s__('UsageQuota|Wiki content.'),
  },
];

export const projectHelpPaths = {
  containerRegistry: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
  ),
  usageQuotas: helpPagePath('user/usage_quotas'),
  usageQuotasNamespaceStorageLimit: helpPagePath('user/usage_quotas', {
    anchor: 'namespace-storage-limit',
  }),
  buildArtifacts: helpPagePath('ci/pipelines/job_artifacts', {
    anchor: 'when-job-artifacts-are-deleted',
  }),
  pipelineArtifacts: helpPagePath('/ci/pipelines/pipeline_artifacts', {
    anchor: 'when-pipeline-artifacts-are-deleted',
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
