import { GlLink, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';
import GitlabUniversitySection from '~/ci/pipeline_editor/components/drawer/sections/gitlab_university_section.vue';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

Vue.config.ignoredElements = ['gl-emoji'];

describe('GitLab University section', () => {
  let wrapper;
  let trackingSpy;
  const GITLAB_UNIVERSITY_LINK = 'https://university.gitlab.com/pages/ci-cd-content';

  const createComponent = () => {
    wrapper = shallowMount(GitlabUniversitySection, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findSectionComponent = () => wrapper.findComponent(SectionComponent);
  const findGitLabUniversityLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji and title', () => {
    expect(findSectionComponent().exists()).toBe(true);
    expect(findSectionComponent().props()).toMatchObject({
      emoji: 'mortar_board',
      title: 'Learn CI/CD with GitLab University',
    });
  });

  it('renders the body text', () => {
    expect(wrapper.text()).toContain('Learn how to set up and use GitLab CI/CD');
  });

  it('renders the link', () => {
    expect(findGitLabUniversityLink().exists()).toBe(true);
  });

  it('links to the correct URL', () => {
    expect(findGitLabUniversityLink().attributes().href).toBe(GITLAB_UNIVERSITY_LINK);
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks gl university url click', async () => {
      const { label } = pipelineEditorTrackingOptions;
      const GITLAB_UNIVERSITY_TRACKING_LINK = 'visit_help_drawer_link_gitlab_university';

      await findGitLabUniversityLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, GITLAB_UNIVERSITY_TRACKING_LINK, {
        label,
      });
    });
  });
});
