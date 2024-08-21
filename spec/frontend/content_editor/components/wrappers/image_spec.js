import { NodeViewWrapper } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImageWrapper from '~/content_editor/components/wrappers/image.vue';
import { createTestEditor, mockChainedCommands } from '../../test_utils';
import '~/content_editor/services/upload_helpers';

jest.mock('~/content_editor/services/upload_helpers', () => ({
  uploadingStates: {
    image12: true,
  },
}));

describe('content/components/wrappers/image_spec', () => {
  let wrapper;
  let tiptapEditor;
  let updateAttributes;

  const createWrapper = (node = {}) => {
    tiptapEditor = createTestEditor();
    updateAttributes = jest.fn();
    wrapper = shallowMountExtended(ImageWrapper, {
      propsData: {
        editor: tiptapEditor,
        node,
        getPos: jest.fn().mockReturnValue(12),
        updateAttributes,
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

    expect(findImage().attributes()).toMatchObject({
      src: 'image.png',
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
      src: 'image.png',
      alt: 'My Image',
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

  describe.each`
    handle  | htmlElementAttributes              | tiptapNodeAttributes
    ${'nw'} | ${{ width: '300', height: '75' }}  | ${{ width: 300, height: 75 }}
    ${'ne'} | ${{ width: '500', height: '125' }} | ${{ width: 500, height: 125 }}
    ${'sw'} | ${{ width: '300', height: '75' }}  | ${{ width: 300, height: 75 }}
    ${'se'} | ${{ width: '500', height: '125' }} | ${{ width: 500, height: 125 }}
  `(
    'resizing using $handle on mousedown + mousemove',
    ({ handle, htmlElementAttributes, tiptapNodeAttributes }) => {
      let handleEl;

      const initialMousePosition = { screenX: 200, screenY: 200 };
      const finalMousePosition = { screenX: 300, screenY: 300 };

      const initComponent = (width = 400, height = 100) => {
        jest.spyOn(window, 'getComputedStyle').mockReturnValue({ width: '400px', height: '100px' });

        createWrapper({
          type: { name: 'image' },
          attrs: { src: 'image.png', alt: 'My Image', width, height },
        });

        handleEl = findHandle(handle);
        handleEl.element.dispatchEvent(new MouseEvent('mousedown', initialMousePosition));
        document.dispatchEvent(new MouseEvent('mousemove', finalMousePosition));
      };

      beforeEach(() => {
        initComponent();
      });

      it('resizes the image properly', () => {
        expect(findImage().attributes()).toMatchObject(htmlElementAttributes);
      });

      describe('when mouse is released', () => {
        let commands;
        beforeEach(() => {
          commands = mockChainedCommands(tiptapEditor, ['focus', 'setNodeSelection', 'run']);
          document.dispatchEvent(new MouseEvent('mouseup'));
        });

        it('updates image attributes to resized attributes', () => {
          document.dispatchEvent(new MouseEvent('mouseup'));

          expect(updateAttributes).toHaveBeenCalledWith(tiptapNodeAttributes);
        });

        it('sets focus back to the image', () => {
          expect(commands.setNodeSelection).toHaveBeenCalledWith(12);
          expect(commands.focus).toHaveBeenCalled();
          expect(commands.run).toHaveBeenCalled();
        });
      });

      describe('when image dimensions are auto', () => {
        beforeEach(() => {
          initComponent('auto', 'auto');
        });

        it('resizes the image properly', () => {
          expect(findImage().attributes()).toMatchObject(htmlElementAttributes);
        });
      });
    },
  );

  it('resize image when its attributes are updated', async () => {
    createWrapper({
      type: { name: 'image' },
      attrs: { src: 'image.png', alt: 'My Image', width: 400, height: 100 },
    });

    await wrapper.setProps({ node: { attrs: { width: 150, height: 150 } } });

    expect(findImage().attributes()).toMatchObject({
      width: '150',
      height: '150',
    });
  });
});
