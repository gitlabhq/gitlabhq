import { __, s__ } from '~/locale';

const SELECT_ENTITIES = s__('OfflineTransfer|Select entities');
const CONFIGURE = s__('OfflineTransfer|Configure');
const REVIEW = s__('OfflineTransfer|Review');
const EXPORT = __('Export');

export const OFFLINE_EXPORT_STEPS = [SELECT_ENTITIES, CONFIGURE, REVIEW, EXPORT];

export const FORM_STEPPER_TAB_COLOR = {
  active: 'gl-text-link gl-font-bold',
  pending: 'gl-text-subtle',
  completed: 'gl-text-blue-500',
};

export const FORM_STEPPER_TAB_BORDER_COLOR = {
  active: 'gl-border-b-link',
  pending: 'gl-border-b-neutral-300',
  completed: 'gl-border-b-blue-300',
};
