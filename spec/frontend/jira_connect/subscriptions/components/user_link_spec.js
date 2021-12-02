import { GlSprintf } from '@gitlab/ui';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  getGitlabSignInURL: jest.fn().mockImplementation((path) => Promise.resolve(path)),
}));

describe('SubscriptionsList', () => {
  let wrapper;

  const createComponent = (propsData = {}, { provide } = {}) => {
    wrapper = shallowMountExtended(UserLink, {
      propsData,
      provide,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findSignInLink = () => wrapper.findByTestId('sign-in-link');
  const findGitlabUserLink = () => wrapper.findByTestId('gitlab-user-link');
  const findSprintf = () => wrapper.findComponent(GlSprintf);

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    userSignedIn | hasSubscriptions | expectGlSprintf | expectGlLink
    ${true}      | ${false}         | ${true}         | ${false}
    ${false}     | ${true}          | ${false}        | ${true}
    ${true}      | ${true}          | ${true}         | ${false}
    ${false}     | ${false}         | ${false}        | ${false}
  `(
    'when `userSignedIn` is $userSignedIn and `hasSubscriptions` is $hasSubscriptions',
    ({ userSignedIn, hasSubscriptions, expectGlSprintf, expectGlLink }) => {
      it('renders template correctly', () => {
        createComponent({
          userSignedIn,
          hasSubscriptions,
        });

        expect(findSprintf().exists()).toBe(expectGlSprintf);
        expect(findSignInLink().exists()).toBe(expectGlLink);
      });
    },
  );

  describe('sign in link', () => {
    it('renders with correct href', async () => {
      const mockUsersPath = '/user';
      createComponent(
        {
          userSignedIn: false,
          hasSubscriptions: true,
        },
        { provide: { usersPath: mockUsersPath } },
      );

      await waitForPromises();

      expect(findSignInLink().exists()).toBe(true);
      expect(findSignInLink().attributes('href')).toBe(mockUsersPath);
    });
  });

  describe('gitlab user link', () => {
    window.gon = { current_username: 'root' };

    beforeEach(() => {
      createComponent(
        {
          userSignedIn: true,
          hasSubscriptions: true,
        },
        { provide: { gitlabUserPath: '/root' } },
      );
    });

    it('renders with correct href', () => {
      expect(findGitlabUserLink().attributes('href')).toBe('/root');
    });

    it('contains GitLab user handle', () => {
      expect(findGitlabUserLink().text()).toBe('@root');
    });
  });
});
