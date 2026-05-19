import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImageWrapper from '~/content_editor/components/wrappers/image.vue';
import { createTestEditor } from '../../test_utils';
import '~/content_editor/services/upload_helpers';

jest.mock('~/content_editor/services/upload_helpers', () => ({
  uploadingStates: {
    image12: true,
  },
}));

describe('content/components/wrappers/image_spec', () => {
  let wrapper;

  const createWrapper = (node = {}) => {
    const tiptapEditor = createTestEditor();
    wrapper = shallowMountExtended(ImageWrapper, {
      propsData: {
        editor: tiptapEditor,
        node,
        getPos: jest.fn().mockReturnValue(12),
        updateAttributes: jest.fn(),
      },
    });
  };

  const findHandle = (handle) => wrapper.findByTestId(`image-resize-${handle}`);
  const findImage = () => wrapper.find('img');

  it('renders an image with the given attributes', () => {
    createWrapper({
      type: { name: 'image' },
      attrs: { src: 'image.png', alt: 'My Image', width: 200, height: 200 },
    });

    expect(findImage().element.src).toBe('image.png');
    expect(findImage().attributes()).toMatchObject({
      alt: 'My Image',
      height: '200',
      width: '200',
    });
  });

  it('marks the image as draggable', () => {
    createWrapper({ type: { name: 'image' }, attrs: { src: 'image.png', alt: 'My Image' } });

    expect(findImage().attributes()).toMatchObject({
      draggable: 'true',
      'data-drag-handle': '',
    });
  });

  it('sets width and height to auto if not provided', () => {
    createWrapper({ type: { name: 'image' }, attrs: { src: 'image.png', alt: 'My Image' } });

    expect(findImage().attributes()).toMatchObject({
      height: 'auto',
      width: 'auto',
    });
  });

  it('hides the wrapper component if it is a stale upload', () => {
    createWrapper({
      type: { name: 'image' },
      attrs: { src: 'image.png', alt: 'My Image', uploading: 'image12' },
    });

    expect(wrapper.findComponent(NodeViewWrapper).attributes('style')).toBe('display: none;');
  });

  it('does not hide the wrapper component if the upload is not stale', () => {
    createWrapper({
      type: { name: 'image' },
      attrs: { src: 'image.png', alt: 'My Image', uploading: 'image13' },
    });

    expect(wrapper.findComponent(NodeViewWrapper).attributes('style')).toBeUndefined();
  });

  it('renders corner resize handles', () => {
    createWrapper({ type: { name: 'image' }, attrs: { src: 'image.png', alt: 'My Image' } });

    expect(findHandle('nw').exists()).toBe(true);
    expect(findHandle('ne').exists()).toBe(true);
    expect(findHandle('sw').exists()).toBe(true);
    expect(findHandle('se').exists()).toBe(true);
  });
});
