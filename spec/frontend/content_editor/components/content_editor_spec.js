import { EditorContent } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import ContentEditorAlert from '~/content_editor/components/content_editor_alert.vue';
import ContentEditorProvider from '~/content_editor/components/content_editor_provider.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import FormattingBubbleMenu from '~/content_editor/components/formatting_bubble_menu.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import LoadingIndicator from '~/content_editor/components/loading_indicator.vue';
import { emitEditorEvent } from '../test_utils';

jest.mock('~/emoji');

describe('ContentEditor', () => {
  let wrapper;
  let contentEditor;
  let renderMarkdown;
  const uploadsPath = '/uploads';

  const findEditorElement = () => wrapper.findByTestId('content-editor');
  const findEditorContent = () => wrapper.findComponent(EditorContent);
  const createWrapper = (propsData = {}) => {
    renderMarkdown = jest.fn();

    wrapper = shallowMountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        uploadsPath,
        ...propsData,
      },
      stubs: {
        EditorStateObserver,
        ContentEditorProvider,
      },
      listeners: {
        initialized(editor) {
          contentEditor = editor;
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('triggers initialized event and provides contentEditor instance as event data', () => {
    createWrapper();

    expect(contentEditor).not.toBeFalsy();
  });

  it('renders EditorContent component and provides tiptapEditor instance', () => {
    createWrapper();

    const editorContent = findEditorContent();

    expect(editorContent.props().editor).toBe(contentEditor.tiptapEditor);
    expect(editorContent.classes()).toContain('md');
  });

  it('renders ContentEditorProvider component', () => {
    createWrapper();

    expect(wrapper.findComponent(ContentEditorProvider).exists()).toBe(true);
  });

  it('renders top toolbar component', () => {
    createWrapper();

    expect(wrapper.findComponent(TopToolbar).exists()).toBe(true);
  });

  it('adds is-focused class when focus event is emitted', async () => {
    createWrapper();

    await emitEditorEvent({ tiptapEditor: contentEditor.tiptapEditor, event: 'focus' });

    expect(findEditorElement().classes()).toContain('is-focused');
  });

  it('removes is-focused class when blur event is emitted', async () => {
    createWrapper();

    await emitEditorEvent({ tiptapEditor: contentEditor.tiptapEditor, event: 'focus' });
    await emitEditorEvent({ tiptapEditor: contentEditor.tiptapEditor, event: 'blur' });

    expect(findEditorElement().classes()).not.toContain('is-focused');
  });

  it('emits change event when document is updated', async () => {
    createWrapper();

    await emitEditorEvent({ tiptapEditor: contentEditor.tiptapEditor, event: 'update' });

    expect(wrapper.emitted('change')).toEqual([
      [
        {
          empty: contentEditor.empty,
        },
      ],
    ]);
  });

  it('renders content_editor_alert component', () => {
    createWrapper();

    expect(wrapper.findComponent(ContentEditorAlert).exists()).toBe(true);
  });

  it('renders loading indicator component', () => {
    createWrapper();

    expect(wrapper.findComponent(LoadingIndicator).exists()).toBe(true);
  });

  it('renders formatting bubble menu', () => {
    createWrapper();

    expect(wrapper.findComponent(FormattingBubbleMenu).exists()).toBe(true);
  });
});
