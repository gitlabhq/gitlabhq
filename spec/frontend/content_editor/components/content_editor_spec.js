import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { EditorContent, Editor } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { CONTENT_EDITOR_PASTE } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import ContentEditorAlert from '~/content_editor/components/content_editor_alert.vue';
import ContentEditorProvider from '~/content_editor/components/content_editor_provider.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import CodeBlockBubbleMenu from '~/content_editor/components/bubble_menus/code_block_bubble_menu.vue';
import LinkBubbleMenu from '~/content_editor/components/bubble_menus/link_bubble_menu.vue';
import MediaBubbleMenu from '~/content_editor/components/bubble_menus/media_bubble_menu.vue';
import ReferenceBubbleMenu from '~/content_editor/components/bubble_menus/reference_bubble_menu.vue';
import FormattingToolbar from '~/content_editor/components/formatting_toolbar.vue';
import LoadingIndicator from '~/content_editor/components/loading_indicator.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { KEYDOWN_EVENT } from '~/content_editor/constants';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mockChainedCommands } from '../test_utils';

describe('ContentEditor', () => {
  let wrapper;
  let renderMarkdown;
  let mock;
  const uploadsPath = '/uploads';

  const findEditorElement = () => wrapper.findByTestId('content-editor');
  const findEditorContent = () => wrapper.findComponent(EditorContent);
  const findEditorStateObserver = () => wrapper.findComponent(EditorStateObserver);
  const findLoadingIndicator = () => wrapper.findComponent(LoadingIndicator);
  const findContentEditorAlert = () => wrapper.findComponent(ContentEditorAlert);
  const createWrapper = ({ markdown, autofocus, ...props } = {}) => {
    wrapper = shallowMountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        markdownDocsPath: '/docs/markdown',
        uploadsPath,
        markdown,
        autofocus,
        placeholder: 'Enter some text here...',
        ...props,
      },
      stubs: {
        EditorStateObserver,
        ContentEditorProvider,
        ContentEditorAlert,
        GlLink,
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    // ignore /-/emojis requests
    mock.onGet().reply(HTTP_STATUS_OK, []);

    renderMarkdown = jest.fn();
  });

  afterEach(() => {
    mock.restore();
  });

  it('triggers initialized event', () => {
    createWrapper();

    expect(wrapper.emitted('initialized')).toHaveLength(1);
  });

  it('renders EditorContent component and provides tiptapEditor instance', async () => {
    const markdown = 'hello world';

    createWrapper({ markdown });

    renderMarkdown.mockResolvedValueOnce({ body: markdown });

    await nextTick();

    const editorContent = findEditorContent();

    expect(editorContent.props().editor).toBeInstanceOf(Editor);
    expect(editorContent.classes()).toContain('md');
  });

  it('allows setting the tiptap editor to autofocus', async () => {
    createWrapper({ autofocus: 'start' });

    await nextTick();

    expect(findEditorContent().props().editor.options.autofocus).toBe('start');
  });

  it('renders ContentEditorProvider component', () => {
    createWrapper();

    expect(wrapper.findComponent(ContentEditorProvider).exists()).toBe(true);
  });

  it('renders toolbar component', () => {
    createWrapper();

    expect(wrapper.findComponent(FormattingToolbar).exists()).toBe(true);
  });

  it('displays an attachment button', () => {
    createWrapper();

    expect(wrapper.findComponent(FormattingToolbar).props().hideAttachmentButton).toBe(false);
  });

  it('hides the attachment button if attachments are disabled', () => {
    createWrapper({ disableAttachments: true });

    expect(wrapper.findComponent(FormattingToolbar).props().hideAttachmentButton).toBe(true);
  });

  describe('when setting initial content', () => {
    it('displays loading indicator', async () => {
      createWrapper();

      await nextTick();

      expect(findLoadingIndicator().exists()).toBe(true);
    });

    it('emits loading event', async () => {
      createWrapper();

      await nextTick();

      expect(wrapper.emitted('loading')).toHaveLength(1);
    });

    describe('succeeds', () => {
      beforeEach(async () => {
        renderMarkdown.mockResolvedValueOnce({ body: '' });

        createWrapper({ markdown: '' });
        await nextTick();
      });

      it('hides loading indicator', async () => {
        await nextTick();
        expect(findLoadingIndicator().exists()).toBe(false);
      });

      it('emits loadingSuccess event', () => {
        expect(wrapper.emitted('loadingSuccess')).toHaveLength(1);
      });

      it('shows placeholder text', () => {
        expect(wrapper.text()).toContain('Enter some text here...');
      });
    });

    describe('fails', () => {
      beforeEach(async () => {
        renderMarkdown.mockRejectedValueOnce(new Error());

        createWrapper({ markdown: 'hello world' });
        await nextTick();
      });

      it('sets the content editor as read only when loading content fails', async () => {
        await nextTick();

        expect(findEditorContent().props().editor.isEditable).toBe(false);
      });

      it('hides loading indicator', async () => {
        await nextTick();

        expect(findLoadingIndicator().exists()).toBe(false);
      });

      it('emits loadingError event', () => {
        expect(wrapper.emitted('loadingError')).toHaveLength(1);
      });

      it('displays error alert indicating that the content editor failed to load', () => {
        expect(findContentEditorAlert().text()).toContain(
          'An error occurred while trying to render the rich text editor. Please try again.',
        );
      });

      describe('when clicking the retry button in the loading error alert and loading succeeds', () => {
        beforeEach(async () => {
          renderMarkdown.mockResolvedValueOnce({ body: 'hello markdown' });
          await wrapper.findComponent(GlAlert).vm.$emit('primaryAction');
        });

        it('hides the loading error alert', () => {
          expect(findContentEditorAlert().text()).toBe('');
        });

        it('sets the content editor as writable', async () => {
          await nextTick();

          expect(findEditorContent().props().editor.isEditable).toBe(true);
        });
      });
    });
  });

  describe('when focused event is emitted', () => {
    beforeEach(async () => {
      createWrapper();

      findEditorStateObserver().vm.$emit('focus');

      await nextTick();
    });

    it('adds is-focused class when focus event is emitted', () => {
      expect(findEditorElement().classes()).toContain('is-focused');
    });

    it('removes is-focused class when blur event is emitted', async () => {
      findEditorStateObserver().vm.$emit('blur');

      await nextTick();

      expect(findEditorElement().classes()).not.toContain('is-focused');
    });

    it('hides placeholder text', () => {
      expect(wrapper.text()).not.toContain('Enter some text here...');
    });
  });

  describe('when editorStateObserver emits docUpdate event', () => {
    let markdown;

    beforeEach(async () => {
      markdown = 'Loaded content';

      renderMarkdown.mockResolvedValueOnce({ body: markdown });

      createWrapper({ markdown: 'initial content' });

      await nextTick();
      await waitForPromises();

      findEditorStateObserver().vm.$emit('docUpdate');
    });

    it('emits change event with the latest markdown', () => {
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            markdown,
            changed: false,
            empty: false,
          },
        ],
      ]);
    });

    it('hides the placeholder text', () => {
      expect(wrapper.text()).not.toContain('Enter some text here...');
    });
  });

  describe('when editorStateObserver emits keydown event', () => {
    it('bubbles up event', () => {
      const event = new Event('keydown');

      createWrapper();

      findEditorStateObserver().vm.$emit(KEYDOWN_EVENT, event);
      expect(wrapper.emitted(KEYDOWN_EVENT)).toEqual([[event]]);
    });
  });

  it.each`
    name           | component
    ${'link'}      | ${LinkBubbleMenu}
    ${'media'}     | ${MediaBubbleMenu}
    ${'codeBlock'} | ${CodeBlockBubbleMenu}
    ${'reference'} | ${ReferenceBubbleMenu}
  `('renders $name bubble menu', ({ component }) => {
    createWrapper();

    expect(wrapper.findComponent(component).exists()).toBe(true);
  });

  it('renders an editor mode dropdown', () => {
    createWrapper();

    expect(wrapper.findComponent(EditorModeSwitcher).exists()).toBe(true);
  });

  it('pastes content when CONTENT_EDITOR_READY_PASTE event is emitted', async () => {
    const markdown = 'hello world';

    createWrapper({ markdown });

    renderMarkdown.mockResolvedValueOnce({ body: markdown });

    await waitForPromises();

    const editorContent = findEditorContent();
    const commands = mockChainedCommands(editorContent.props('editor'), [
      'focus',
      'pasteContent',
      'run',
    ]);

    markdownEditorEventHub.$emit(CONTENT_EDITOR_PASTE, 'Paste content');

    await waitForPromises();

    expect(commands.focus).toHaveBeenCalled();
    expect(commands.pasteContent).toHaveBeenCalledWith('Paste content');
    expect(commands.run).toHaveBeenCalled();
  });
});
