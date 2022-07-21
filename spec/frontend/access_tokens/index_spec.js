/* eslint-disable vue/require-prop-types */
/* eslint-disable vue/one-component-per-file */
import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import {
  initAccessTokenTableApp,
  initExpiresAtField,
  initNewAccessTokenApp,
  initTokensApp,
} from '~/access_tokens';
import * as AccessTokenTableApp from '~/access_tokens/components/access_token_table_app.vue';
import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import * as NewAccessTokenApp from '~/access_tokens/components/new_access_token_app.vue';
import * as TokensApp from '~/access_tokens/components/tokens_app.vue';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from '~/access_tokens/constants';
import { __, sprintf } from '~/locale';

describe('access tokens', () => {
  let wrapper;

  afterEach(() => {
    wrapper?.destroy();
    resetHTMLFixture();
  });

  describe('initAccessTokenTableApp', () => {
    const accessTokenType = 'personal access token';
    const accessTokenTypePlural = 'personal access tokens';
    const initialActiveAccessTokens = [{ id: '1' }];

    const FakeAccessTokenTableApp = Vue.component('FakeComponent', {
      inject: [
        'accessTokenType',
        'accessTokenTypePlural',
        'initialActiveAccessTokens',
        'noActiveTokensMessage',
        'showRole',
      ],
      props: [
        'accessTokenType',
        'accessTokenTypePlural',
        'initialActiveAccessTokens',
        'noActiveTokensMessage',
        'showRole',
      ],
      render: () => null,
    });
    AccessTokenTableApp.default = FakeAccessTokenTableApp;

    it('mounts the component and provides required values', () => {
      setHTMLFixture(
        `<div id="js-access-token-table-app"
        data-access-token-type="${accessTokenType}"
        data-access-token-type-plural="${accessTokenTypePlural}"
        data-initial-active-access-tokens=${JSON.stringify(initialActiveAccessTokens)}
        >
        </div>`,
      );

      const vueInstance = initAccessTokenTableApp();

      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent(FakeAccessTokenTableApp);

      expect(component.exists()).toBe(true);

      expect(component.props()).toMatchObject({
        // Required value
        accessTokenType,
        accessTokenTypePlural,
        initialActiveAccessTokens,

        // Default values
        noActiveTokensMessage: sprintf(__('This user has no active %{accessTokenTypePlural}.'), {
          accessTokenTypePlural,
        }),
        showRole: false,
      });
    });

    it('mounts the component and provides all values', () => {
      const noActiveTokensMessage = 'This group has no active access tokens.';
      setHTMLFixture(
        `<div id="js-access-token-table-app"
          data-access-token-type="${accessTokenType}"
          data-access-token-type-plural="${accessTokenTypePlural}"
          data-initial-active-access-tokens=${JSON.stringify(initialActiveAccessTokens)}
          data-no-active-tokens-message="${noActiveTokensMessage}"
          data-show-role
          >
        </div>`,
      );

      const vueInstance = initAccessTokenTableApp();

      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent(FakeAccessTokenTableApp);

      expect(component.exists()).toBe(true);
      expect(component.props()).toMatchObject({
        accessTokenType,
        accessTokenTypePlural,
        initialActiveAccessTokens,
        noActiveTokensMessage,
        showRole: true,
      });
    });

    it('returns `null`', () => {
      expect(initNewAccessTokenApp()).toBe(null);
    });
  });

  describe('initExpiresAtField', () => {
    describe('when mount element exists', () => {
      const nameAttribute = 'access_tokens[expires_at]';
      const idAttribute = 'access_tokens_expires_at';

      beforeEach(() => {
        setHTMLFixture(
          `<div class="js-access-tokens-expires-at">
            <input
              name="access_tokens[expires_at]"
              data-js-name="expiresAt"
              id="access_tokens_expires_at"
              placeholder="Foo bar"
              value="1,2"
            />
          </div>`,
        );
      });

      it('mounts component and sets `inputAttrs` prop', async () => {
        wrapper = createWrapper(initExpiresAtField());
        const component = wrapper.findComponent(ExpiresAtField);

        expect(component.exists()).toBe(true);
        expect(component.props('inputAttrs')).toEqual({
          name: nameAttribute,
          id: idAttribute,
          value: '1,2',
          placeholder: 'Foo bar',
        });
      });
    });

    describe('when mount element does not exist', () => {
      it('returns `null`', () => {
        expect(initExpiresAtField()).toBe(null);
      });
    });
  });

  describe('initNewAccessTokenApp', () => {
    it('mounts the component and sets `accessTokenType` prop', () => {
      const accessTokenType = 'personal access token';
      setHTMLFixture(
        `<div id="js-new-access-token-app" data-access-token-type="${accessTokenType}"></div>`,
      );

      const FakeNewAccessTokenApp = Vue.component('FakeComponent', {
        inject: ['accessTokenType'],
        props: ['accessTokenType'],
        render: () => null,
      });
      NewAccessTokenApp.default = FakeNewAccessTokenApp;

      const vueInstance = initNewAccessTokenApp();

      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent(FakeNewAccessTokenApp);

      expect(component.exists()).toBe(true);
      expect(component.props('accessTokenType')).toEqual(accessTokenType);
    });

    it('returns `null`', () => {
      expect(initNewAccessTokenApp()).toBe(null);
    });
  });

  describe('initTokensApp', () => {
    it('mounts the component and provides`tokenTypes` ', () => {
      const tokensData = {
        [FEED_TOKEN]: FEED_TOKEN,
        [INCOMING_EMAIL_TOKEN]: INCOMING_EMAIL_TOKEN,
        [STATIC_OBJECT_TOKEN]: STATIC_OBJECT_TOKEN,
      };
      setHTMLFixture(
        `<div id="js-tokens-app" data-tokens-data=${JSON.stringify(tokensData)}></div>`,
      );

      const FakeTokensApp = Vue.component('FakeComponent', {
        inject: ['tokenTypes'],
        props: ['tokenTypes'],
        render: () => null,
      });
      TokensApp.default = FakeTokensApp;

      const vueInstance = initTokensApp();

      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent(FakeTokensApp);

      expect(component.exists()).toBe(true);
      expect(component.props('tokenTypes')).toEqual(tokensData);
    });

    it('returns `null`', () => {
      expect(initNewAccessTokenApp()).toBe(null);
    });
  });
});
