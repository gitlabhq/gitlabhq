import { GlSprintf } from '@gitlab/ui';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';
import SignInOauthButton from '~/jira_connect/subscriptions/components/sign_in_oauth_button.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

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

  const findGitlabUserLink = () => wrapper.findByTestId('gitlab-user-link');
  const findSprintf = () => wrapper.findComponent(GlSprintf);
  const findOauthButton = () => wrapper.findComponent(SignInOauthButton);

  describe.each`
    userSignedIn | hasSubscriptions | expectGlSprintf | expectOauthButton
    ${false}     | ${false}         | ${false}        | ${false}
    ${false}     | ${true}          | ${false}        | ${true}
    ${true}      | ${false}         | ${true}         | ${false}
    ${true}      | ${true}          | ${true}         | ${false}
  `(
    'when `userSignedIn` is $userSignedIn, `hasSubscriptions` is $hasSubscriptions',
    ({ userSignedIn, hasSubscriptions, expectGlSprintf, expectOauthButton }) => {
      it('renders template correctly', () => {
        createComponent(
          {
            userSignedIn,
            hasSubscriptions,
          },
          {
            provide: {
              oauthMetadata: {},
            },
          },
        );

        expect(findSprintf().exists()).toBe(expectGlSprintf);
        expect(findOauthButton().exists()).toBe(expectOauthButton);
      });
    },
  );

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
