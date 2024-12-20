import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import {
  initAccessTokenTableApp,
  initExpiresAtField,
  initNewAccessTokenApp,
  initTokensApp,
} from '~/access_tokens';
import AccessTokenTableApp from '~/access_tokens/components/access_token_table_app.vue';
import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import NewAccessTokenApp from '~/access_tokens/components/new_access_token_app.vue';
import TokensApp from '~/access_tokens/components/tokens_app.vue';
import { FORM_SELECTOR } from '~/access_tokens/components/constants';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from '~/access_tokens/constants';
import { sprintf } from '~/locale';

describe('access tokens', () => {
  let wrapper;

  afterEach(() => {
    wrapper?.destroy();
    resetHTMLFixture();
  });

  describe('initAccessTokenTableApp', () => {
    const accessTokenType = 'personal access token';
    const accessTokenTypePlural = 'personal access tokens';
    const initialActiveAccessTokens = [{ revoked_path: '1' }];

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
      const component = wrapper.findComponent({ name: 'AccessTokenTableRoot' });

      expect(component.exists()).toBe(true);
      expect(wrapper.findComponent(AccessTokenTableApp).vm).toMatchObject({
        // Required value
        accessTokenType,
        accessTokenTypePlural,
        initialActiveAccessTokens,

        // Default values
        noActiveTokensMessage: sprintf('This user has no active %{accessTokenTypePlural}.', {
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
      const component = wrapper.findComponent({ name: 'AccessTokenTableRoot' });

      expect(component.exists()).toBe(true);
      expect(component.findComponent(AccessTokenTableApp).vm).toMatchObject({
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

      it('mounts component and sets `inputAttrs` prop', () => {
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
        `<div id="js-new-access-token-app" data-access-token-type="${accessTokenType}"></div>
        <form id="${FORM_SELECTOR.slice(1)}"></form>`,
      );

      const vueInstance = initNewAccessTokenApp();
      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent({ name: 'NewAccessTokenRoot' });

      expect(component.exists()).toBe(true);
      expect(component.findComponent(NewAccessTokenApp).vm).toMatchObject({ accessTokenType });
    });

    it('returns `null`', () => {
      expect(initNewAccessTokenApp()).toBe(null);
    });
  });

  describe('initTokensApp', () => {
    it('mounts the component and provides`tokenTypes`', () => {
      const tokensData = {
        [FEED_TOKEN]: FEED_TOKEN,
        [INCOMING_EMAIL_TOKEN]: INCOMING_EMAIL_TOKEN,
        [STATIC_OBJECT_TOKEN]: STATIC_OBJECT_TOKEN,
      };
      setHTMLFixture(
        `<div id="js-tokens-app" data-tokens-data=${JSON.stringify(tokensData)}></div>`,
      );

      const vueInstance = initTokensApp();
      wrapper = createWrapper(vueInstance);
      const component = wrapper.findComponent(TokensApp);

      expect(component.exists()).toBe(true);
      expect(component.vm).toMatchObject({ tokenTypes: tokensData });
    });

    it('returns `null`', () => {
      expect(initNewAccessTokenApp()).toBe(null);
    });
  });
});
