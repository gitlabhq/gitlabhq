import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching project storage statistics',
);
export const LEARN_MORE_LABEL = __('Learn more.');
export const USAGE_QUOTAS_LABEL = s__('UsageQuota|Usage Quotas');
export const TOTAL_USAGE_TITLE = s__('UsageQuota|Usage breakdown');
export const TOTAL_USAGE_SUBTITLE = s__(
  'UsageQuota|Includes artifacts, repositories, wiki, uploads, and other items.',
);
export const TOTAL_USAGE_DEFAULT_TEXT = __('Not applicable.');
export const HELP_LINK_ARIA_LABEL = s__('UsageQuota|%{linkTitle} help link');
export const RECALCULATE_REPOSITORY_LABEL = s__('UsageQuota|Recalculate repository usage');

export const projectContainerRegistryPopoverContent = s__(
  'UsageQuotas|The project-level storage statistics for the Container Registry are directional only and do not include savings for instance-wide deduplication.',
);

export const containerRegistryId = 'containerRegistrySize';
export const containerRegistryPopoverId = 'container-registry-popover';
export const uploadsId = 'uploadsSize';
export const uploadsPopoverId = 'uploads-popover';
export const uploadsPopoverContent = s__(
  'NamespaceStorage|Uploads are not counted in namespace storage quotas.',
);

export const PROJECT_TABLE_LABEL_PROJECT = __('Project');
export const PROJECT_TABLE_LABEL_STORAGE_TYPE = s__('UsageQuota|Storage type');
export const PROJECT_TABLE_LABEL_USAGE = s__('UsageQuota|Usage');

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'containerRegistrySize',
    name: s__('UsageQuota|Container Registry'),
    description: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
    ),
  },
  {
    id: 'buildArtifactsSize',
    name: s__('UsageQuota|Artifacts'),
    description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
    tooltip: s__('UsageQuota|Artifacts is a sum of build and pipeline artifacts.'),
  },
  {
    id: 'lfsObjectsSize',
    name: s__('UsageQuota|LFS storage'),
    description: s__('UsageQuota|Audio samples, videos, datasets, and graphics.'),
  },
  {
    id: 'packagesSize',
    name: s__('UsageQuota|Packages'),
    description: s__('UsageQuota|Code packages and container images.'),
  },
  {
    id: 'repositorySize',
    name: s__('UsageQuota|Repository'),
    description: s__('UsageQuota|Git repository.'),
  },
  {
    id: 'snippetsSize',
    name: s__('UsageQuota|Snippets'),
    description: s__('UsageQuota|Shared bits of code and text.'),
  },
  {
    id: 'uploadsSize',
    name: s__('UsageQuota|Uploads'),
    description: s__('UsageQuota|File attachments and smaller design graphics.'),
  },
  {
    id: 'wikiSize',
    name: s__('UsageQuota|Wiki'),
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
