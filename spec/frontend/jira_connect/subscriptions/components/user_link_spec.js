import { GlSprintf } from '@gitlab/ui';
import UserLink from '~/jira_connect/subscriptions/components/user_link.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('UserLink', () => {
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

  const findGitlabUserLink = () => wrapper.findByTestId('gitlab-user-link');
  const findSprintf = () => wrapper.findComponent(GlSprintf);

  it('renders template correctly', () => {
    createComponent();

    expect(findSprintf().exists()).toBe(true);
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

          createComponent({ user }, { provide: { gitlabUserPath } });
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
