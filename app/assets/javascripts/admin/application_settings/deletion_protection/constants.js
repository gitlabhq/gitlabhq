import { __, s__ } from '~/locale';

export const I18N_DELETION_PROTECTION = {
  label: s__('DeletionSettings|Deletion protection'),
  helpText: s__(
    'DeletionSettings|Period that deleted groups and projects will remain restorable for. Personal projects are always deleted immediately.',
  ),
  learnMore: __('Learn more.'),
  days: __('days'),
};

export const DEL_ADJ_PERIOD_MAX_LIMIT = 90;
export const DEL_ADJ_PERIOD_MIN_LIMIT = 1;

export const DEL_ADJ_PERIOD_MAX_LIMIT_ERROR = s__(
  'DeletionSettings|Maximum deletion protection duration is 90 days.',
);

export const DEL_ADJ_PERIOD_MIN_LIMIT_ERROR = s__(
  'DeletionSettings|Minimum deletion protection duration is 1 day.',
);
