import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VisualizeAndLintSection from '~/ci/pipeline_editor/components/drawer/sections/visualize_and_lint_section.vue';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

Vue.config.ignoredElements = ['gl-emoji'];

describe('Visual and Lint section', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(VisualizeAndLintSection);
  };

  const findSectionComponent = () => wrapper.findComponent(SectionComponent);

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji and title', () => {
    expect(findSectionComponent().exists()).toBe(true);
    expect(findSectionComponent().props()).toMatchObject({
      emoji: 'bulb',
      title: 'Tip: Visualize and validate your pipeline',
    });
  });

  it('renders the content', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });
});
