import { s__, __ } from '~/locale';

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'buildArtifactsSize',
    name: s__('UsageQuota|Artifacts'),
    description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
    warningMessage: s__(
      'UsageQuota|There is a known issue with Artifact storage where the total could be incorrect for some projects. More details and progress are available in %{warningLinkStart}the epic%{warningLinkEnd}.',
    ),
    warningLink: 'https://gitlab.com/groups/gitlab-org/-/epics/5380',
  },
  {
    id: 'lfsObjectsSize',
    name: s__('UsageQuota|LFS Storage'),
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
    description: s__('UsageQuota|Git repository, managed by the Gitaly service.'),
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

export const PROJECT_TABLE_LABELS = {
  STORAGE_TYPE: s__('UsageQuota|Storage type'),
  VALUE: s__('UsageQuota|Usage'),
};

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching project storage statistics',
);

export const LEARN_MORE_LABEL = s__('Learn more.');
export const USAGE_QUOTAS_LABEL = s__('UsageQuota|Usage Quotas');
export const HELP_LINK_ARIA_LABEL = s__('UsageQuota|%{linkTitle} help link');
export const TOTAL_USAGE_DEFAULT_TEXT = __('N/A');
export const TOTAL_USAGE_TITLE = s__('UsageQuota|Usage Breakdown');
export const TOTAL_USAGE_SUBTITLE = s__(
  'UsageQuota|Includes project registry, artifacts, packages, wiki, uploads and other items.',
);
