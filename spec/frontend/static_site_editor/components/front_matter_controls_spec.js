import { shallowMount } from '@vue/test-utils';

import { GlFormGroup } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';

import FrontMatterControls from '~/static_site_editor/components/front_matter_controls.vue';

describe('~/static_site_editor/components/front_matter_controls.vue', () => {
  let wrapper;

  // TODO Refactor and update `sourceContentHeaderObjYAML` in mock_data when !41230 lands
  const settings = {
    layout: 'handbook-page-toc',
    title: 'Handbook',
    twitter_image: '/images/tweets/handbook-gitlab.png',
    suppress_header: true,
    extra_css: ['sales-and-free-trial-common.css', 'form-to-resource.css'],
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(FrontMatterControls, {
      propsData: {
        settings,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render only the supported GlFormGroup types', () => {
    expect(wrapper.findAll(GlFormGroup)).toHaveLength(3);
  });

  it.each`
    key
    ${'layout'}
    ${'title'}
    ${'twitter_image'}
  `('renders field when key is $key', ({ key }) => {
    const glFormGroup = wrapper.find(`#sse-front-matter-form-group-${key}`);
    const glFormInput = wrapper.find(`#sse-front-matter-control-${key}`);

    expect(glFormGroup.exists()).toBe(true);
    expect(glFormGroup.attributes().label).toBe(humanize(key));

    expect(glFormInput.exists()).toBe(true);
    expect(glFormInput.attributes().value).toBe(settings[key]);
  });

  it.each`
    key
    ${'suppress_header'}
    ${'extra_css'}
  `('does not render field when key is $key', ({ key }) => {
    const glFormInput = wrapper.find(`#sse-front-matter-control-${key}`);

    expect(glFormInput.exists()).toBe(false);
  });

  it('emits updated settings when nested control updates', () => {
    const elId = `#sse-front-matter-control-title`;
    const glFormInput = wrapper.find(elId);
    const newTitle = 'New title';

    glFormInput.vm.$emit('input', newTitle);

    const newSettings = { ...settings, title: newTitle };

    expect(wrapper.emitted('updateSettings')[0][0]).toMatchObject(newSettings);
  });
});
