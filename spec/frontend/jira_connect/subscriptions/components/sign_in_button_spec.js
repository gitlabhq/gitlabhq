import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getLocation } from '~/jira_connect/subscriptions/utils';
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
    getLocationValue           | expectedHref
    ${''}                      | ${MOCK_USERS_PATH}
    ${undefined}               | ${MOCK_USERS_PATH}
    ${'https://test.jira.com'} | ${`${MOCK_USERS_PATH}?return_to=${encodeURIComponent('https://test.jira.com')}`}
  `('when getLocation resolves with `$getLocationValue`', ({ getLocationValue, expectedHref }) => {
    it(`sets button href to ${expectedHref}`, async () => {
      getLocation.mockResolvedValue(getLocationValue);
      createComponent();

      expect(getLocation).toHaveBeenCalled();
      await waitForPromises();

      expect(findButton().attributes('href')).toBe(expectedHref);
    });
  });
});
