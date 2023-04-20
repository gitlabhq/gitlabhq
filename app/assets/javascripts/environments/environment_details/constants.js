import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ENVIRONMENT_DETAILS_PAGE_SIZE = 20;
export const ENVIRONMENT_DETAILS_TABLE_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'id',
    label: __('ID'),
    columnClass: 'gl-w-5p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'triggerer',
    label: __('Triggerer'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'commit',
    label: __('Commit'),
    columnClass: 'gl-w-20p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'job',
    label: __('Job'),
    columnClass: 'gl-w-15p',
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'created',
    label: __('Created'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
  },
  {
    key: 'deployed',
    label: __('Deployed'),
    columnClass: 'gl-w-10p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
  },
  {
    key: 'actions',
    label: __('Actions'),
    columnClass: 'gl-w-15p',
    tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
  },
];

export const translations = {
  emptyStateTitle: s__("Deployments|You don't have any deployments right now."),
  emptyStatePrimaryButton: __('Read more'),
  emptyStateDescription: s__(
    'Deployments|Define environments in the deploy stage(s) in %{code_open}.gitlab-ci.yml%{code_close} to track deployments here.',
  ),
  nextPageButtonLabel: __('Next'),
  previousPageButtonLabel: __('Prev'),
  redeployButtonTitle: s__('Environments|Re-deploy to environment'),
  rollbackButtonTitle: s__('Environments|Rollback environment'),
};

export const codeBlockPlaceholders = { code: ['code_open', 'code_close'] };

export const environmentsHelpPagePath = helpPagePath('ci/environments/index.md');
