import { shallowMount } from '@vue/test-utils';
import mediaResize from '~/content_editor/components/wrappers/media_resize';

describe('content_editor/components/wrappers/media_resize', () => {
  let wrapper;
  let updateAttributes;
  let mockEditor;

  const TestComponent = {
    mixins: [mediaResize('media')],
    template: '<div><img ref="media" :width="resizeWidth" :height="resizeHeight" /></div>',
  };

  const createWrapper = (attrs = {}) => {
    mockEditor = {
      chain: jest.fn().mockReturnThis(),
      focus: jest.fn().mockReturnThis(),
      setNodeSelection: jest.fn().mockReturnThis(),
      run: jest.fn().mockReturnThis(),
    };
    updateAttributes = jest.fn();
    wrapper = shallowMount(TestComponent, {
      propsData: {
        node: { attrs: { width: 400, height: 100, ...attrs } },
        editor: mockEditor,
        getPos: jest.fn().mockReturnValue(12),
        updateAttributes,
        selected: false,
      },
    });
  };

  const findImage = () => wrapper.find('img');

  it('exposes resizeHandles via $options', () => {
    createWrapper();

    expect(wrapper.vm.$options.resizeHandles).toEqual(['ne', 'nw', 'se', 'sw']);
  });

  describe('resizeWidth and resizeHeight', () => {
    it('returns node dimensions when no drag is active', () => {
      createWrapper({ width: 200, height: 150 });

      expect(wrapper.vm.resizeWidth).toBe(200);
      expect(wrapper.vm.resizeHeight).toBe(150);
    });

    it('returns auto when node has no dimensions', () => {
      createWrapper({ width: null, height: null });

      expect(wrapper.vm.resizeWidth).toBe('auto');
      expect(wrapper.vm.resizeHeight).toBe('auto');
    });

    it('updates when node attributes change', async () => {
      createWrapper({ width: 400, height: 100 });

      expect(findImage().attributes()).toMatchObject({ width: '400', height: '100' });

      await wrapper.setProps({ node: { attrs: { width: 150, height: 150 } } });

      expect(findImage().attributes()).toMatchObject({ width: '150', height: '150' });
    });
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
      const initialMousePosition = { screenX: 200, screenY: 200 };
      const finalMousePosition = { screenX: 300, screenY: 300 };

      const initResize = (width = 400, height = 100) => {
        jest.spyOn(window, 'getComputedStyle').mockReturnValue({ width: '400px', height: '100px' });

        createWrapper({ width, height });

        wrapper.vm.onDragStart(handle, new MouseEvent('mousedown', initialMousePosition));
        document.dispatchEvent(new MouseEvent('mousemove', finalMousePosition));
      };

      beforeEach(() => {
        initResize();
      });

      it('resizes the element properly', () => {
        expect(findImage().attributes()).toMatchObject(htmlElementAttributes);
      });

      describe('when mouse is released', () => {
        beforeEach(() => {
          document.dispatchEvent(new MouseEvent('mouseup'));
        });

        it('updates attributes to resized dimensions', () => {
          expect(updateAttributes).toHaveBeenCalledWith(tiptapNodeAttributes);
        });

        it('sets focus back and selects the node', () => {
          expect(mockEditor.chain).toHaveBeenCalled();
          expect(mockEditor.focus).toHaveBeenCalled();
          expect(mockEditor.setNodeSelection).toHaveBeenCalledWith(12);
          expect(mockEditor.run).toHaveBeenCalled();
        });
      });

      describe('when element dimensions are auto', () => {
        beforeEach(() => {
          initResize('auto', 'auto');
        });

        it('resizes the element properly using computed style', () => {
          expect(findImage().attributes()).toMatchObject(htmlElementAttributes);
        });
      });
    },
  );

  describe('onNativeDragStart', () => {
    it('prevents native dragstart when a resize handle is active', () => {
      createWrapper();

      wrapper.vm.onDragStart('se', new MouseEvent('mousedown', { screenX: 100, screenY: 100 }));

      const dragEvent = new Event('dragstart', { cancelable: true });
      wrapper.element.dispatchEvent(dragEvent);

      expect(dragEvent.defaultPrevented).toBe(true);
    });

    it('allows native dragstart when no resize handle is active', () => {
      createWrapper();

      const dragEvent = new Event('dragstart', { cancelable: true });
      wrapper.element.dispatchEvent(dragEvent);

      expect(dragEvent.defaultPrevented).toBe(false);
    });
  });

  describe('lifecycle', () => {
    it('cleans up document event listeners on destroy', () => {
      createWrapper();

      const removeSpy = jest.spyOn(document, 'removeEventListener');

      wrapper.destroy();

      const removedEvents = removeSpy.mock.calls.map(([event]) => event);
      expect(removedEvents).toContain('mousemove');
      expect(removedEvents).toContain('mouseup');
    });
  });
});
