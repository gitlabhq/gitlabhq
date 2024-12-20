import Vue from 'vue';

import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { __, sprintf } from '~/locale';
import Translate from '~/vue_shared/translate';
import AccessTokenTableApp from './components/access_token_table_app.vue';
import InactiveAccessTokenTableApp from './components/inactive_access_token_table_app.vue';
import ExpiresAtField from './components/expires_at_field.vue';
import NewAccessTokenApp from './components/new_access_token_app.vue';
import TokensApp from './components/tokens_app.vue';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from './constants';

Vue.use(Translate);

export const initAccessTokenTableApp = () => {
  const el = document.querySelector('#js-access-token-table-app');

  if (!el) {
    return null;
  }

  const {
    accessTokenType,
    accessTokenTypePlural,
    backendPagination,
    initialActiveAccessTokens: initialActiveAccessTokensJson,
    noActiveTokensMessage: noTokensMessage,
  } = el.dataset;

  // Default values
  const noActiveTokensMessage =
    noTokensMessage ||
    sprintf(__('This user has no active %{accessTokenTypePlural}.'), { accessTokenTypePlural });
  const showRole = 'showRole' in el.dataset;

  const initialActiveAccessTokens = JSON.parse(initialActiveAccessTokensJson);

  return new Vue({
    el,
    name: 'AccessTokenTableRoot',
    provide: {
      accessTokenType,
      accessTokenTypePlural,
      backendPagination: parseBoolean(backendPagination),
      initialActiveAccessTokens,
      noActiveTokensMessage,
      showRole,
    },
    render(h) {
      return h(AccessTokenTableApp);
    },
  });
};

export const initInactiveAccessTokenTableApp = () => {
  const el = document.querySelector('#js-inactive-access-token-table-app');

  if (!el) {
    return null;
  }

  const { noInactiveTokensMessage, paginationUrl } = el.dataset;

  return new Vue({
    el,
    name: 'InactiveAccessTokenTableRoot',
    provide: {
      noInactiveTokensMessage,
      paginationUrl,
    },
    render(h) {
      return h(InactiveAccessTokenTableApp);
    },
  });
};

export const initExpiresAtField = () => {
  const el = document.querySelector('.js-access-tokens-expires-at');

  if (!el) {
    return null;
  }

  const { expiresAt: inputAttrs } = parseRailsFormFields(el);
  const { minDate, maxDate, defaultDateOffset, description } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(ExpiresAtField, {
        props: {
          inputAttrs,
          minDate: minDate ? new Date(minDate) : undefined,
          maxDate: maxDate ? new Date(maxDate) : undefined,
          defaultDateOffset: defaultDateOffset ? Number(defaultDateOffset) : undefined,
          description,
        },
      });
    },
  });
};

export const initNewAccessTokenApp = () => {
  const el = document.querySelector('#js-new-access-token-app');

  if (!el) {
    return null;
  }

  const { accessTokenType } = el.dataset;

  return new Vue({
    el,
    name: 'NewAccessTokenRoot',
    provide: {
      accessTokenType,
    },
    render(h) {
      return h(NewAccessTokenApp);
    },
  });
};

export const initTokensApp = () => {
  const el = document.getElementById('js-tokens-app');

  if (!el) return null;

  const tokensData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.tokensData), {
    deep: true,
  });

  const tokenTypes = {
    [FEED_TOKEN]: tokensData[FEED_TOKEN],
    [INCOMING_EMAIL_TOKEN]: tokensData[INCOMING_EMAIL_TOKEN],
    [STATIC_OBJECT_TOKEN]: tokensData[STATIC_OBJECT_TOKEN],
  };

  return new Vue({
    el,
    provide: {
      tokenTypes,
    },
    render(createElement) {
      return createElement(TokensApp);
    },
  });
};
