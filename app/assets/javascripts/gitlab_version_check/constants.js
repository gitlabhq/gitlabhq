import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from '~/constants';

export const STATUS_TYPES = {
  SUCCESS: 'success',
  WARNING: 'warning',
  DANGER: 'danger',
};

export const UPGRADE_DOCS_URL = helpPagePath('update/_index');

export const ABOUT_RELEASES_PAGE = `${PROMO_URL}/releases/categories/releases/`;

export const ALERT_MODAL_ID = 'security-patch-upgrade-alert-modal';

export const COOKIE_EXPIRATION = 3;

export const COOKIE_SUFFIX = '-hide-alert-modal';

export const TRACKING_ACTIONS = {
  RENDER: 'render',
  CLICK_LINK: 'click_link',
  CLICK_BUTTON: 'click_button',
};

export const TRACKING_LABELS = {
  MODAL: 'security_patch_upgrade_alert_modal',
  LEARN_MORE_LINK: 'security_patch_upgrade_alert_modal_learn_more',
  REMIND_ME_BTN: 'security_patch_upgrade_alert_modal_remind_3_days',
  UPGRADE_BTN_LINK: 'security_patch_upgrade_alert_modal_upgrade_now',
  DISMISS: 'security_patch_upgrade_alert_modal_close',
};
