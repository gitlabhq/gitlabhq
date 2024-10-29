import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import GettingStartedSection from '~/ci/pipeline_editor/components/drawer/sections/getting_started_section.vue';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

Vue.config.ignoredElements = ['gl-emoji'];

describe('Getting started section', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GettingStartedSection);
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

  it('renders the content', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });
});
