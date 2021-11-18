import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getGitlabSignInURL } from '~/jira_connect/subscriptions/utils';
import SignInButton from '~/jira_connect/subscriptions/components/sign_in_button.vue';
import waitForPromises from 'helpers/wait_for_promises';

const MOCK_USERS_PATH = '/user';

jest.mock('~/jira_connect/subscriptions/utils');

describe('SignInButton', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(SignInButton, {
      propsData: {
        usersPath: MOCK_USERS_PATH,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a button', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
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
});
