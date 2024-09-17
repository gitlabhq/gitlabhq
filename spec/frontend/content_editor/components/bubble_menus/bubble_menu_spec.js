import { BubbleMenuPlugin } from '@tiptap/extension-bubble-menu';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import { createTestEditor } from '../../test_utils';

jest.mock('@tiptap/extension-bubble-menu');

describe('content_editor/components/bubble_menus/bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  const pluginKey = 'key';
  const shouldShow = jest.fn();
  const tippyOptions = { placement: 'bottom' };
  const pluginInitializationResult = {};

  const buildEditor = () => {
    tiptapEditor = createTestEditor();
  };

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMountExtended(BubbleMenu, {
      provide: {
        tiptapEditor,
      },
      propsData: {
        pluginKey,
        shouldShow,
        tippyOptions,
        ...propsData,
      },
      slots: {
        default: '<div>menu content</div>',
      },
    });
  };

  const setupMocks = () => {
    BubbleMenuPlugin.mockReturnValueOnce(pluginInitializationResult);
    jest.spyOn(tiptapEditor, 'registerPlugin').mockImplementationOnce(() => true);
  };

  const invokeTippyEvent = (eventName, eventArgs) => {
    const pluginConfig = BubbleMenuPlugin.mock.calls[0][0];

    pluginConfig.tippyOptions[eventName](eventArgs);
  };

  beforeEach(() => {
    buildEditor();
    setupMocks();
  });

  it('initializes BubbleMenuPlugin', async () => {
    createWrapper({});

    await nextTick();

    expect(BubbleMenuPlugin).toHaveBeenCalledWith({
      pluginKey,
      editor: tiptapEditor,
      shouldShow,
      element: wrapper.vm.$el,
      tippyOptions: expect.objectContaining({
        onHidden: expect.any(Function),
        onShow: expect.any(Function),
        popperOptions: {
          strategy: 'fixed',
        },
        maxWidth: '400px',
        ...tippyOptions,
      }),
    });

    expect(tiptapEditor.registerPlugin).toHaveBeenCalledWith(pluginInitializationResult);
  });

  it('does not render default slot by default', async () => {
    createWrapper({});

    await nextTick();

    expect(wrapper.text()).not.toContain('menu content');
  });

  describe('when onShow event handler is invoked', () => {
    const onShowArgs = {};

    beforeEach(async () => {
      createWrapper({});

      await nextTick();

      invokeTippyEvent('onShow', onShowArgs);
    });

    it('displays the menu content', () => {
      expect(wrapper.text()).toContain('menu content');
    });

    it('emits show event', () => {
      expect(wrapper.emitted('show')).toEqual([[onShowArgs]]);
    });
  });

  describe('when onHidden event handler is invoked', () => {
    const onHiddenArgs = {};

    beforeEach(async () => {
      createWrapper({});

      await nextTick();

      invokeTippyEvent('onShow', onHiddenArgs);
      invokeTippyEvent('onHidden', onHiddenArgs);
    });

    it('displays the menu content', () => {
      expect(wrapper.text()).not.toContain('menu content');
    });

    it('emits show event', () => {
      expect(wrapper.emitted('hidden')).toEqual([[onHiddenArgs]]);
    });
  });
});
