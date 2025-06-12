import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { GlButton } from '@gitlab/ui';
import FileBrowserDrawerToggle from '~/rapid_diffs/app/file_browser_drawer_toggle.vue';
import { useFileBrowser } from '~/diffs/stores/file_browser';

Vue.use(PiniaVuePlugin);

describe('FileBrowserDrawerToggle', () => {
  let wrapper;
  let pinia;

  const createComponent = () => {
    wrapper = shallowMount(FileBrowserDrawerToggle, {
      pinia,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
    useFileBrowser();
  });

  it('toggles file browser drawer', () => {
    createComponent();
    wrapper.findComponent(GlButton).vm.$emit('click');
    expect(useFileBrowser().toggleFileBrowserDrawerVisibility).toHaveBeenCalled();
  });
});
