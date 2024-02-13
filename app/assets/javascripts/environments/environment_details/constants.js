import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ENVIRONMENT_DETAILS_QUERY_POLLING_INTERVAL = 3000;
export const ENVIRONMENT_DETAILS_PAGE_SIZE = 20;
export const ENVIRONMENT_DETAILS_TABLE_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'id',
    label: __('ID'),
    columnClass: 'gl-w-5p',
    tdClass: 'gl-vertical-align-middle!',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'triggerer',
    label: __('Triggerer'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'commit',
    label: __('Commit'),
    columnClass: 'gl-w-20p',
    tdClass: 'gl-vertical-align-middle!',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'job',
    label: __('Job'),
    columnClass: 'gl-w-15p',
    tdClass: 'gl-vertical-align-middle!',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'created',
    label: __('Created'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'deployed',
    label: __('Deployed'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
    thClass: 'gl-border-t-none!',
  },
  {
    key: 'actions',
    label: __('Actions'),
    columnClass: 'gl-w-15p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
    thClass: 'gl-border-t-none!',
  },
];

export const translations = {
  emptyStateTitle: s__('Deployments|No deployment history'),
  emptyStatePrimaryButton: __('Read more'),
  emptyStateDescription: s__(
    'Deployments|Add an %{codeStart}environment:name%{codeEnd} to your CI/CD jobs to register a deployment action. %{linkStart}Learn more about environments.%{linkEnd}',
  ),
  nextPageButtonLabel: __('Next'),
  previousPageButtonLabel: __('Prev'),
  redeployButtonTitle: s__('Environments|Re-deploy to environment'),
  rollbackButtonTitle: s__('Environments|Rollback environment'),
};

export const environmentsLearnMorePath = helpPagePath('ci/environments/index');
export const environmentsHelpPagePath = helpPagePath('ci/yaml/index', { anchor: 'environment' });
