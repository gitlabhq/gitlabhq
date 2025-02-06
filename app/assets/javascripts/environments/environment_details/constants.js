import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL = 3000;
export const ENVIRONMENT_DETAILS_PAGE_SIZE = 20;
export const ENVIRONMENT_DETAILS_TABLE_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    columnClass: 'gl-w-2/20',
    tdClass: '!gl-align-middle',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'id',
    label: __('ID'),
    columnClass: 'gl-w-1/20',
    tdClass: '!gl-align-middle',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'triggerer',
    label: __('Triggerer'),
    columnClass: 'gl-w-2/20',
    tdClass: '!gl-align-middle',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'commit',
    label: __('Commit'),
    columnClass: 'gl-w-4/20',
    tdClass: '!gl-align-middle',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'job',
    label: __('Job'),
    columnClass: 'gl-w-3/20',
    tdClass: '!gl-align-middle',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'created',
    label: __('Created'),
    columnClass: 'gl-w-2/20',
    tdClass: '!gl-align-middle gl-whitespace-nowrap',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'finished',
    label: __('Finished'),
    columnClass: 'gl-w-2/20',
    tdClass: '!gl-align-middle gl-whitespace-nowrap',
    thClass: '!gl-border-t-0',
  },
  {
    key: 'actions',
    label: __('Actions'),
    columnClass: 'gl-w-3/20',
    tdClass: '!gl-align-middle gl-whitespace-nowrap',
    thClass: '!gl-border-t-0',
  },
];

export const translations = {
  emptyStateTitle: s__('Deployments|No deployment history'),
  emptyStatePrimaryButton: __('Read more'),
  emptyStateDescription: s__(
    'Deployments|Add an %{codeStart}environment:name%{codeEnd} to your CI/CD jobs to register a deployment action. %{linkStart}Learn more about environments.%{linkEnd}',
  ),
  redeployButtonTitle: s__('Environments|Re-deploy to environment'),
  rollbackButtonTitle: s__('Environments|Rollback environment'),
};

export const environmentsLearnMorePath = helpPagePath('ci/environments/_index');
export const environmentsHelpPagePath = helpPagePath('ci/yaml/_index', { anchor: 'environment' });

export const DEPLOYMENTS_SORT_OPTIONS = [
  {
    value: 'createdAt',
    text: s__('Environment|Created on'),
  },
  {
    value: 'finishedAt',
    text: s__('Environment|Finished on'),
  },
];

export const DIRECTION_DESCENDING = 'DESC';
export const DIRECTION_ASCENDING = 'ASC';
