import { __, s__ } from '~/locale';

const SELECT_ENTITIES = s__('OfflineTransfer|Select entities');
const CONFIGURE = s__('OfflineTransfer|Configure');
const EXPORT = __('Export');

export const OFFLINE_EXPORT_TAB_HEADINGS = [SELECT_ENTITIES, CONFIGURE, EXPORT];

export const FORM_STEPPER_TAB_STATE = {
  ACTIVE: 'active',
  PENDING: 'pending',
  COMPLETED: 'completed',
};

export const FORM_STEPPER_TAB_COLOR = {
  [FORM_STEPPER_TAB_STATE.ACTIVE]: 'gl-text-link gl-font-bold',
  [FORM_STEPPER_TAB_STATE.PENDING]: 'gl-text-subtle',
  [FORM_STEPPER_TAB_STATE.COMPLETED]: 'gl-text-default',
};

export const FORM_STEPPER_ACTIVE_TAB_BORDER =
  'gl-border-b-2 gl-border-b-[color:var(--gl-tab-selected-indicator-color-default)]';
