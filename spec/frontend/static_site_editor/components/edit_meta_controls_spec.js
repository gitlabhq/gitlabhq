import { shallowMount } from '@vue/test-utils';

import { GlFormInput, GlFormTextarea } from '@gitlab/ui';

import EditMetaControls from '~/static_site_editor/components/edit_meta_controls.vue';

import { mergeRequestMeta } from '../mock_data';

describe('~/static_site_editor/components/edit_meta_modal.vue', () => {
  let wrapper;
  const { title, description } = mergeRequestMeta;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditMetaControls, {
      propsData: {
        title,
        description,
        ...propsData,
      },
    });
  };

  const findGlFormInputTitle = () => wrapper.find(GlFormInput);
  const findGlFormTextAreaDescription = () => wrapper.find(GlFormTextarea);

  beforeEach(() => {
    buildWrapper();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the title input', () => {
    expect(findGlFormInputTitle().exists()).toBe(true);
  });

  it('renders the description input', () => {
    expect(findGlFormTextAreaDescription().exists()).toBe(true);
  });

  it('forwards the title prop to the title input', () => {
    expect(findGlFormInputTitle().attributes().value).toBe(title);
  });

  it('forwards the description prop to the description input', () => {
    expect(findGlFormTextAreaDescription().attributes().value).toBe(description);
  });

  it('emits updated settings when title input updates', () => {
    const newTitle = 'New title';

    findGlFormInputTitle().vm.$emit('input', newTitle);

    const newSettings = { description, title: newTitle };

    expect(wrapper.emitted('updateSettings')[0][0]).toMatchObject(newSettings);
  });

  it('emits updated settings when description textarea updates', () => {
    const newDescription = 'New description';

    findGlFormTextAreaDescription().vm.$emit('input', newDescription);

    const newSettings = { description: newDescription, title };

    expect(wrapper.emitted('updateSettings')[0][0]).toMatchObject(newSettings);
  });
});
