import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GettingStartedSection from '~/ci/pipeline_editor/components/drawer/sections/getting_started_section.vue';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

Vue.config.ignoredElements = ['gl-emoji'];

describe('Getting started section', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(GettingStartedSection, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findSectionComponent = () => wrapper.findComponent(SectionComponent);

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji and title', () => {
    expect(findSectionComponent().exists()).toBe(true);
    expect(findSectionComponent().props()).toMatchObject({
      emoji: 'wave',
      title: 'Get started with GitLab CI/CD',
    });
  });

  it('renders the expected text content', () => {
    const expectedText =
      'GitLab CI/CD can automatically build, test, and deploy your application. The pipeline stages and jobs are defined in a .gitlab-ci.yml file. You can edit, visualize and validate the syntax in this file by using the pipeline editor. Use the rules keyword to configure jobs to run in merge requests.';

    expect(wrapper.text()).toContain(expectedText);
  });

  it('renders a link to the help page', () => {
    const link = findLink();
    const expectedLink =
      '/help/ci/pipelines/merge_request_pipelines.html#add-jobs-to-merge-request-pipelines';

    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(expectedLink);
  });
});
