import { shallowMount } from '@vue/test-utils';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import ImageDiffViewer from '~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue';

describe('ImageViewer', () => {
  let wrapper;

  const defaultProps = {
    imageData: {
      old_path: 'old.png',
      new_path: 'new.png',
      old_size: 1024,
      new_size: 2048,
      diff_mode: 'new',
    },
    oldPath: 'old.png',
    newPath: 'new.png',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ImageViewer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('shows image diff viewer', () => {
    createComponent();
    expect(wrapper.findComponent(ImageDiffViewer).exists()).toBe(true);
    expect(wrapper.findComponent(ImageDiffViewer).props()).toMatchObject({
      oldPath: defaultProps.imageData.old_path,
      newPath: defaultProps.imageData.new_path,
      oldSize: defaultProps.imageData.old_size,
      newSize: defaultProps.imageData.new_size,
      diffMode: defaultProps.imageData.diff_mode,
      encodePath: false,
    });
  });
});
