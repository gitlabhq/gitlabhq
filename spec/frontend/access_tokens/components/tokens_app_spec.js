import { merge } from 'lodash';

import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';

import TokensApp from '~/access_tokens/components/tokens_app.vue';
import { FEED_TOKEN, INCOMING_EMAIL_TOKEN, STATIC_OBJECT_TOKEN } from '~/access_tokens/constants';

describe('TokensApp', () => {
  let wrapper;

  const defaultProvide = {
    tokenTypes: {
      [FEED_TOKEN]: {
        enabled: true,
        token: 'DUKu345VD73Py7zz3z89',
        resetPath: '/-/profile/reset_feed_token',
      },
      [INCOMING_EMAIL_TOKEN]: {
        enabled: true,
        token: 'az4a2l5f8ssa0zvdfbhidbzlx',
        resetPath: '/-/profile/reset_incoming_email_token',
      },
      [STATIC_OBJECT_TOKEN]: {
        enabled: true,
        token: 'QHXwGHYioHTgxQnAcyZ-',
        resetPath: '/-/profile/reset_static_object_token',
      },
    },
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(TokensApp, merge({}, { provide: defaultProvide }, options));
  };

  const expectTokenRendered = ({
    testId,
    expectedLabel,
    expectedDescription,
    expectedInputDescription,
    expectedResetPath,
    expectedResetConfirmMessage,
    expectedProps,
  }) => {
    const container = extendedWrapper(wrapper.findByTestId(testId));

    expect(container.findByText(expectedLabel).exists()).toBe(true);
    expect(container.findByText(expectedDescription, { exact: false }).exists()).toBe(true);
    expect(container.findByText(expectedInputDescription, { exact: false }).exists()).toBe(true);
    expect(container.findByText('reset this token').attributes()).toMatchObject({
      'data-confirm': expectedResetConfirmMessage,
      'data-method': 'put',
      href: expectedResetPath,
    });
    expect(container.props()).toMatchObject(expectedProps);
  };

  it('renders all enabled tokens', () => {
    createComponent();

    expectTokenRendered({
      testId: TokensApp.htmlAttributes[FEED_TOKEN].containerTestId,
      expectedLabel: TokensApp.i18n[FEED_TOKEN].label,
      expectedDescription: TokensApp.i18n[FEED_TOKEN].description,
      expectedInputDescription:
        'Keep this token secret. Anyone who has it can read activity and issue RSS feeds or your calendar feed as if they were you.',
      expectedResetPath: defaultProvide.tokenTypes[FEED_TOKEN].resetPath,
      expectedResetConfirmMessage: TokensApp.i18n[FEED_TOKEN].resetConfirmMessage,
      expectedProps: {
        token: defaultProvide.tokenTypes[FEED_TOKEN].token,
        inputId: TokensApp.htmlAttributes[FEED_TOKEN].inputId,
        inputLabel: TokensApp.i18n[FEED_TOKEN].label,
        copyButtonTitle: TokensApp.i18n[FEED_TOKEN].copyButtonTitle,
      },
    });

    expectTokenRendered({
      testId: TokensApp.htmlAttributes[INCOMING_EMAIL_TOKEN].containerTestId,
      expectedLabel: TokensApp.i18n[INCOMING_EMAIL_TOKEN].label,
      expectedDescription: TokensApp.i18n[INCOMING_EMAIL_TOKEN].description,
      expectedInputDescription:
        'Keep this token secret. Anyone who has it can create issues as if they were you.',
      expectedResetPath: defaultProvide.tokenTypes[INCOMING_EMAIL_TOKEN].resetPath,
      expectedResetConfirmMessage: TokensApp.i18n[INCOMING_EMAIL_TOKEN].resetConfirmMessage,
      expectedProps: {
        token: defaultProvide.tokenTypes[INCOMING_EMAIL_TOKEN].token,
        inputId: TokensApp.htmlAttributes[INCOMING_EMAIL_TOKEN].inputId,
        inputLabel: TokensApp.i18n[INCOMING_EMAIL_TOKEN].label,
        copyButtonTitle: TokensApp.i18n[INCOMING_EMAIL_TOKEN].copyButtonTitle,
      },
    });

    expectTokenRendered({
      testId: TokensApp.htmlAttributes[STATIC_OBJECT_TOKEN].containerTestId,
      expectedLabel: TokensApp.i18n[STATIC_OBJECT_TOKEN].label,
      expectedDescription: TokensApp.i18n[STATIC_OBJECT_TOKEN].description,
      expectedInputDescription:
        'Keep this token secret. Anyone who has it can access repository static objects as if they were you.',
      expectedResetPath: defaultProvide.tokenTypes[STATIC_OBJECT_TOKEN].resetPath,
      expectedResetConfirmMessage: TokensApp.i18n[STATIC_OBJECT_TOKEN].resetConfirmMessage,
      expectedProps: {
        token: defaultProvide.tokenTypes[STATIC_OBJECT_TOKEN].token,
        inputId: TokensApp.htmlAttributes[STATIC_OBJECT_TOKEN].inputId,
        inputLabel: TokensApp.i18n[STATIC_OBJECT_TOKEN].label,
        copyButtonTitle: TokensApp.i18n[STATIC_OBJECT_TOKEN].copyButtonTitle,
      },
    });
  });

  it("doesn't render disabled tokens", () => {
    createComponent({
      provide: {
        tokenTypes: {
          [FEED_TOKEN]: {
            enabled: false,
          },
        },
      },
    });

    expect(
      wrapper.findByTestId(TokensApp.htmlAttributes[FEED_TOKEN].containerTestId).exists(),
    ).toBe(false);
  });

  describe('when there are tokens missing an `i18n` definition', () => {
    it('renders without errors', () => {
      createComponent({
        provide: {
          tokenTypes: {
            fooBar: {
              enabled: true,
              token: 'rewjoa58dfm54jfkdlsdf',
              resetPath: '/-/profile/foo_bar',
            },
          },
        },
      });

      expect(
        wrapper.findByTestId(TokensApp.htmlAttributes[FEED_TOKEN].containerTestId).exists(),
      ).toBe(true);
    });
  });
});
