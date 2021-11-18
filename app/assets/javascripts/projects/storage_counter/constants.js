import { s__, __ } from '~/locale';

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'buildArtifactsSize',
    name: s__('UsageQuota|Artifacts'),
    description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
    warningMessage: s__(
      'UsageQuota|Because of a known issue, the artifact total for some projects may be incorrect. For more details, read %{warningLinkStart}the epic%{warningLinkEnd}.',
    ),
    warningLink: 'https://gitlab.com/groups/gitlab-org/-/epics/5380',
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

export const PROJECT_TABLE_LABELS = {
  STORAGE_TYPE: s__('UsageQuota|Storage type'),
  VALUE: s__('UsageQuota|Usage'),
};

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching project storage statistics',
);

export const LEARN_MORE_LABEL = __('Learn more.');
export const USAGE_QUOTAS_LABEL = s__('UsageQuota|Usage Quotas');
export const HELP_LINK_ARIA_LABEL = s__('UsageQuota|%{linkTitle} help link');
export const TOTAL_USAGE_DEFAULT_TEXT = __('N/A');
export const TOTAL_USAGE_TITLE = s__('UsageQuota|Usage breakdown');
export const TOTAL_USAGE_SUBTITLE = s__(
  'UsageQuota|Includes artifacts, repositories, wiki, uploads, and other items.',
);
