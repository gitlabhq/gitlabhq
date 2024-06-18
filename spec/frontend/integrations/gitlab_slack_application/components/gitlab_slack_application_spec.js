import { GlButton, GlLink } from '@gitlab/ui';

import { nextTick } from 'vue';
import GitlabSlackApplication from '~/integrations/gitlab_slack_application/components/gitlab_slack_application.vue';
import { addProjectToSlack } from '~/integrations/gitlab_slack_application/api';
import { i18n } from '~/integrations/gitlab_slack_application/constants';
import ProjectsDropdown from '~/integrations/gitlab_slack_application/components/projects_dropdown.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { visitUrl } from '~/lib/utils/url_utility';
import { mockProjects } from '../mock_data';

jest.mock('~/integrations/gitlab_slack_application/api');
jest.mock('~/lib/utils/url_utility');

describe('GitlabSlackApplication', () => {
  let wrapper;

  const defaultProps = {
    projects: [],
    gitlabForSlackGifPath: '//gitlabForSlackGifPath',
    signInPath: '//signInPath',
    slackLinkPath: '//slackLinkPath',
    docsPath: '//docsPath',
    gitlabLogoPath: '//gitlabLogoPath',
    slackLogoPath: '//slackLogoPath',
    isSignedIn: true,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GitlabSlackApplication, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findProjectsDropdown = () => wrapper.findComponent(ProjectsDropdown);
  const findAppContent = () => wrapper.findByTestId('gitlab-slack-content');

  describe('template', () => {
    describe('when user is not signed in', () => {
      it('renders "Sign in" button', () => {
        createComponent({
          props: { isSignedIn: false },
        });

        expect(findGlButton().attributes('href')).toBe(defaultProps.signInPath);
      });
    });

    describe('when user is signed in', () => {
      describe('user does not have any projects', () => {
        it('renders empty text', () => {
          createComponent();

          expect(findAppContent().text()).toContain(i18n.noProjects);
          expect(findAppContent().text()).toContain(i18n.noProjectsDescription);
        });

        it('renders "Learn more" link', () => {
          createComponent();

          expect(findGlLink().text()).toBe(i18n.learnMore);
        });
      });

      describe('user has projects', () => {
        beforeEach(() => {
          createComponent({
            props: {
              projects: mockProjects,
            },
          });
        });

        it('renders ProjectsDropdown', () => {
          expect(findProjectsDropdown().props('projects')).toBe(mockProjects);
        });

        it('redirects to slackLinkPath when submitted', async () => {
          const redirectLink = '//redirectLink';
          const mockProject = mockProjects[1];
          const addToSlackData = { data: { add_to_slack_link: redirectLink } };

          addProjectToSlack.mockResolvedValue(addToSlackData);

          findProjectsDropdown().vm.$emit('project-selected', mockProject);
          await nextTick();

          expect(findProjectsDropdown().props('selectedProject')).toBe(mockProject);
          expect(findGlButton().props('disabled')).toBe(false);

          findGlButton().vm.$emit('click');

          await waitForPromises();

          expect(visitUrl).toHaveBeenCalledWith(redirectLink);
        });
      });
    });
  });
});
