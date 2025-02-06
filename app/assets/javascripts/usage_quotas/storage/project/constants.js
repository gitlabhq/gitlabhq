import { s__, __ } from '~/locale';

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
