import { shallowMount } from '@vue/test-utils';
import { GlDeprecatedButton } from '@gitlab/ui';
import EditButton from '~/diffs/components/edit_button.vue';

const editPath = 'test-path';

describe('EditButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(EditButton, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('has correct href attribute', () => {
    createComponent({
      editPath,
      canCurrentUserFork: false,
    });

    expect(wrapper.find(GlDeprecatedButton).attributes('href')).toBe(editPath);
  });

  it('emits a show fork message event if current user can fork', () => {
    createComponent({
      editPath,
      canCurrentUserFork: true,
    });
    wrapper.find(GlDeprecatedButton).trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('showForkMessage')).toBeTruthy();
    });
  });

  it('doesnt emit a show fork message event if current user cannot fork', () => {
    createComponent({
      editPath,
      canCurrentUserFork: false,
    });
    wrapper.find(GlDeprecatedButton).trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('showForkMessage')).toBeFalsy();
    });
  });

  it('doesnt emit a show fork message event if current user can modify blob', () => {
    createComponent({
      editPath,
      canCurrentUserFork: true,
      canModifyBlob: true,
    });
    wrapper.find(GlDeprecatedButton).trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('showForkMessage')).toBeFalsy();
    });
  });

  it('disables button if editPath is empty', () => {
    createComponent({
      editPath: '',
      canCurrentUserFork: true,
      canModifyBlob: true,
    });

    expect(wrapper.find(GlDeprecatedButton).attributes('disabled')).toBe('true');
  });
});
