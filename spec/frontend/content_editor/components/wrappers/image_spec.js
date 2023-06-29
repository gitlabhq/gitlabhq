import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImageWrapper from '~/content_editor/components/wrappers/image.vue';
import { createTestEditor, mockChainedCommands } from '../../test_utils';

describe('content/components/wrappers/image_spec', () => {
  let wrapper;
  let tiptapEditor;

  const createWrapper = (node = {}) => {
    tiptapEditor = createTestEditor();
    wrapper = shallowMountExtended(ImageWrapper, {
      propsData: {
        editor: tiptapEditor,
        node,
        getPos: jest.fn().mockReturnValue(12),
      },
    });
  };

  const findHandle = (handle) => wrapper.findByTestId(`image-resize-${handle}`);
  const findImage = () => wrapper.find('img');

  it('renders an image with the given attributes', () => {
    createWrapper({
      type: 'image',
      attrs: { src: 'image.png', alt: 'My Image', width: 200, height: 200 },
    });

    expect(findImage().attributes()).toMatchObject({
      src: 'image.png',
      alt: 'My Image',
      height: '200',
      width: '200',
    });
  });

  it('sets width and height to auto if not provided', () => {
    createWrapper({ type: 'image', attrs: { src: 'image.png', alt: 'My Image' } });

    expect(findImage().attributes()).toMatchObject({
      src: 'image.png',
      alt: 'My Image',
      height: 'auto',
      width: 'auto',
    });
  });

  it('renders corner resize handles', () => {
    createWrapper({ type: 'image', attrs: { src: 'image.png', alt: 'My Image' } });

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
  `('resizing using $handle', ({ handle, htmlElementAttributes, tiptapNodeAttributes }) => {
    let handleEl;

    const initialMousePosition = { screenX: 200, screenY: 200 };
    const finalMousePosition = { screenX: 300, screenY: 300 };

    beforeEach(() => {
      createWrapper({
        type: 'image',
        attrs: { src: 'image.png', alt: 'My Image', width: 400, height: 100 },
      });

      handleEl = findHandle(handle);
      handleEl.element.dispatchEvent(new MouseEvent('mousedown', initialMousePosition));
      document.dispatchEvent(new MouseEvent('mousemove', finalMousePosition));
    });

    it('resizes the image properly on mousedown+mousemove', () => {
      expect(findImage().attributes()).toMatchObject(htmlElementAttributes);
    });

    it('updates prosemirror doc state on mouse release with final size', () => {
      const commands = mockChainedCommands(tiptapEditor, [
        'focus',
        'updateAttributes',
        'setNodeSelection',
        'run',
      ]);

      document.dispatchEvent(new MouseEvent('mouseup'));

      expect(commands.focus).toHaveBeenCalled();
      expect(commands.updateAttributes).toHaveBeenCalledWith('image', tiptapNodeAttributes);
      expect(commands.setNodeSelection).toHaveBeenCalledWith(12);
      expect(commands.run).toHaveBeenCalled();
    });
  });
});
