import { GlSprintf } from '@gitlab/ui';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  getGitlabSignInURL: jest.fn().mockImplementation((path) => Promise.resolve(path)),
}));

describe('UserLink', () => {
  let wrapper;

  const createComponent = (propsData = {}, { provide } = {}) => {
    wrapper = shallowMountExtended(UserLink, {
      propsData,
      provide,
      stubs: {
        GlSprintf,
        SignInOauthButton,
      },
    });
  };

  const findSignInLink = () => wrapper.findByTestId('sign-in-link');
  const findGitlabUserLink = () => wrapper.findByTestId('gitlab-user-link');
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findOauthButton = () => wrapper.findComponent(SignInOauthButton);

  describe.each`
    userSignedIn | hasSubscriptions | expectGlSprintf | expectGlLink | expectOauthButton | jiraConnectOauthEnabled
    ${true}      | ${false}         | ${true}         | ${false}     | ${false}          | ${false}
    ${false}     | ${true}          | ${false}        | ${true}      | ${false}          | ${false}
    ${true}      | ${true}          | ${true}         | ${false}     | ${false}          | ${false}
    ${false}     | ${false}         | ${false}        | ${false}     | ${false}          | ${false}
    ${false}     | ${true}          | ${false}        | ${false}     | ${true}           | ${true}
  `(
    'when `userSignedIn` is $userSignedIn, `hasSubscriptions` is $hasSubscriptions, `jiraConnectOauthEnabled` is $jiraConnectOauthEnabled',
    ({
      userSignedIn,
      hasSubscriptions,
      expectGlSprintf,
      expectGlLink,
      expectOauthButton,
      jiraConnectOauthEnabled,
    }) => {
      it('renders template correctly', () => {
        createComponent(
          {
            userSignedIn,
            hasSubscriptions,
          },
          {
            provide: {
              glFeatures: {
                jiraConnectOauth: jiraConnectOauthEnabled,
              },
              oauthMetadata: {},
            },
          },
        );

        expect(findSprintf().exists()).toBe(expectGlSprintf);
        expect(findSignInLink().exists()).toBe(expectGlLink);
        expect(findOauthButton().exists()).toBe(expectOauthButton);
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
    describe.each`
      current_username | gitlabUserPath | user                         | expectedUserHandle | expectedUserLink
      ${'root'}        | ${'/root'}     | ${{ username: 'test-user' }} | ${'@root'}         | ${'/root'}
      ${'root'}        | ${'/root'}     | ${undefined}                 | ${'@root'}         | ${'/root'}
      ${undefined}     | ${undefined}   | ${{ username: 'test-user' }} | ${'@test-user'}    | ${'/test-user'}
    `(
      'when current_username=$current_username, gitlabUserPath=$gitlabUserPath and user=$user',
      ({ current_username, gitlabUserPath, user, expectedUserHandle, expectedUserLink }) => {
        beforeEach(() => {
          window.gon = { current_username, relative_root_url: '' };

          createComponent(
            {
              userSignedIn: true,
              hasSubscriptions: true,
              user,
            },
            { provide: { gitlabUserPath } },
          );
        });

        it(`sets href to ${expectedUserLink}`, () => {
          expect(findGitlabUserLink().attributes('href')).toBe(expectedUserLink);
        });

        it(`renders ${expectedUserHandle} as text`, () => {
          expect(findGitlabUserLink().text()).toBe(expectedUserHandle);
        });
      },
    );
  });
});
