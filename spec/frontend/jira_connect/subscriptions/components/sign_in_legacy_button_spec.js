import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';
import SignInLegacyButton from '~/jira_connect/subscriptions/components/sign_in_legacy_button.vue';
import waitForPromises from 'helpers/wait_for_promises';

const MOCK_USERS_PATH = '/user';

jest.mock('~/jira_connect/subscriptions/utils');

describe('SignInLegacyButton', () => {
  let wrapper;

  const createComponent = ({ slots } = {}) => {
    wrapper = shallowMount(SignInLegacyButton, {
      propsData: {
        usersPath: MOCK_USERS_PATH,
      },
      slots,
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  it('displays a button', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().text()).toBe(SignInLegacyButton.i18n.defaultButtonText);
  });

  describe.each`
    expectedHref
    ${MOCK_USERS_PATH}
    ${`${MOCK_USERS_PATH}?return_to=${encodeURIComponent('https://test.jira.com')}`}
  `('when getGitlabSignInURL resolves with `$expectedHref`', ({ expectedHref }) => {
    it(`sets button href to ${expectedHref}`, async () => {
      getGitlabSignInURL.mockResolvedValue(expectedHref);
      createComponent();

      await waitForPromises();

      expect(findButton().attributes('href')).toBe(expectedHref);
    });
  });

  describe('with slot', () => {
    const mockSlotContent = 'custom button content!';
    it('renders slot content in button', () => {
      createComponent({ slots: { default: mockSlotContent } });
      expect(wrapper.text()).toMatchInterpolatedText(mockSlotContent);
    });
  });
});
