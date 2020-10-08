import { shallowMount } from '@vue/test-utils';

import { GlModal } from '@gitlab/ui';

import EditMetaModal from '~/static_site_editor/components/edit_meta_modal.vue';
import EditMetaControls from '~/static_site_editor/components/edit_meta_controls.vue';

import { sourcePath, mergeRequestMeta } from '../mock_data';

describe('~/static_site_editor/components/edit_meta_modal.vue', () => {
  let wrapper;
  const { title, description } = mergeRequestMeta;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditMetaModal, {
      propsData: {
        sourcePath,
        ...propsData,
      },
    });
  };

  const findGlModal = () => wrapper.find(GlModal);
  const findEditMetaControls = () => wrapper.find(EditMetaControls);

  beforeEach(() => {
    buildWrapper();

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the modal', () => {
    expect(findGlModal().exists()).toBe(true);
  });

  it('renders the edit meta controls', () => {
    expect(findEditMetaControls().exists()).toBe(true);
  });

  it('contains the sourcePath in the title', () => {
    expect(findEditMetaControls().props('title')).toContain(sourcePath);
  });

  it('forwards the title prop', () => {
    expect(findEditMetaControls().props('title')).toBe(title);
  });

  it('forwards the description prop', () => {
    expect(findEditMetaControls().props('description')).toBe(description);
  });

  it('emits the primary event with mergeRequestMeta', () => {
    findGlModal().vm.$emit('primary', mergeRequestMeta);
    expect(wrapper.emitted('primary')).toEqual([[mergeRequestMeta]]);
  });

  it('emits the hide event', () => {
    findGlModal().vm.$emit('hide');
    expect(wrapper.emitted('hide')).toEqual([[]]);
  });
});
