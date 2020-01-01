import { shallowMount, createLocalVue } from '@vue/test-utils';
import EditButton from '~/diffs/components/edit_button.vue';

const localVue = createLocalVue();
const editPath = 'test-path';

describe('EditButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(EditButton, {
      localVue,
      propsData: { ...props },
      sync: false,
      attachToDocument: true,
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

    expect(wrapper.attributes('href')).toBe(editPath);
  });

  it('emits a show fork message event if current user can fork', () => {
    createComponent({
      editPath,
      canCurrentUserFork: true,
    });
    wrapper.trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('showForkMessage')).toBeTruthy();
    });
  });

  it('doesnt emit a show fork message event if current user cannot fork', () => {
    createComponent({
      editPath,
      canCurrentUserFork: false,
    });
    wrapper.trigger('click');

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
    wrapper.trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('showForkMessage')).toBeFalsy();
    });
  });
});
