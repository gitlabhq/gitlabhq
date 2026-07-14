import { __ } from '~/locale';

export const MODAL_ID = 'feature-library-modal';

export const TIERS = Object.freeze({
  PREMIUM: 'premium',
  ULTIMATE: 'ultimate',
  ADD_ON: 'add_on',
});

export const ALL_CATEGORY_ID = 'all';

export const ALL_CATEGORY = Object.freeze({ id: ALL_CATEGORY_ID, label: __('All') });

export const FEEDBACK_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/work_items/604008';

export const ITEMS_PER_RENDER_FRAME = 18;
