import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_NEVER_CONTACTED,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_NEVER_CONTACTED,
  STATUS_STALE,
  PARAM_KEY_STATUS,
} from '../../constants';

const options = [
  { value: STATUS_ONLINE, title: I18N_STATUS_ONLINE },
  { value: STATUS_OFFLINE, title: I18N_STATUS_OFFLINE },
  { value: STATUS_NEVER_CONTACTED, title: I18N_STATUS_NEVER_CONTACTED },
  { value: STATUS_STALE, title: I18N_STATUS_STALE },
];

export const statusTokenConfig = {
  icon: 'status',
  title: TOKEN_TITLE_STATUS,
  type: PARAM_KEY_STATUS,
  token: BaseToken,
  unique: true,
  options: options.map(({ value, title }) => ({
    value,
    // Replace whitespace with a special character to avoid
    // splitting this value.
    // Replacing in each option, as translations may also
    // contain spaces!
    // see: https://gitlab.com/gitlab-org/gitlab/-/issues/344142
    // see: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1438
    title: title.replace(/\s/g, '\u00a0'),
  })),
  operators: OPERATORS_IS,
};
