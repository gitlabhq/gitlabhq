import Vue from 'vue';
import VueRouter from 'vue-router';
import { pinia } from '~/pinia/instance';

import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { setUTCTime } from '~/lib/utils/datetime_utility';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { __, sprintf } from '~/locale';
import Translate from '~/vue_shared/translate';
import AccessTokens from '~/vue_shared/access_tokens/components/access_tokens.vue';
import AccessTokenTableApp from './components/access_token_table_app.vue';
import InactiveAccessTokenTableApp from './components/inactive_access_token_table_app.vue';
import ExpiresAtField from './components/expires_at_field.vue';
import NewAccessTokenApp from './components/new_access_token_app.vue';
import TokensApp from './components/tokens_app.vue';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from './constants';

Vue.use(Translate);
Vue.use(VueRouter);

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
    sprintf(
      __('This user has no active %{accessTokenTypePlural}.'),
      { accessTokenTypePlural },
      false,
    );
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
          minDate: setUTCTime(minDate),
          maxDate: maxDate && setUTCTime(maxDate),
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

export const initSharedAccessTokenApp = () => {
  const el = document.querySelector('#js-shared-access-token-app');

  if (!el) {
    return null;
  }

  const {
    accessTokenMaxDate,
    accessTokenMinDate,
    accessTokenAvailableScopes,
    accessTokenName,
    accessTokenDescription,
    accessTokenScopes,
    accessTokenCreate,
    accessTokenRevoke,
    accessTokenRotate,
    accessTokenShow,
  } = el.dataset;

  const router = new VueRouter({ mode: 'history' });

  return new Vue({
    el,
    name: 'AccessTokensRoot',
    router,
    pinia,
    provide: {
      accessTokenAvailableScopes: JSON.parse(accessTokenAvailableScopes),
      accessTokenMaxDate,
      accessTokenMinDate,
      accessTokenCreate,
      accessTokenRevoke,
      accessTokenRotate,
      accessTokenShow,
    },
    render(createElement) {
      return createElement(AccessTokens, {
        props: {
          id: gon.current_user_id,
          tokenName: accessTokenName,
          tokenDescription: accessTokenDescription,
          tokenScopes: accessTokenScopes && JSON.parse(accessTokenScopes),
        },
      });
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
