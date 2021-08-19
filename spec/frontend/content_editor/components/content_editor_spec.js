import { GlLoadingIcon } from '@gitlab/ui';
import { EditorContent } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import ContentEditorError from '~/content_editor/components/content_editor_error.vue';
import ContentEditorProvider from '~/content_editor/components/content_editor_provider.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import {
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
} from '~/content_editor/constants';
import { emitEditorEvent } from '../test_utils';

jest.mock('~/emoji');

describe('ContentEditor', () => {
  let wrapper;
  let contentEditor;
  let renderMarkdown;
  const uploadsPath = '/uploads';

  const findEditorElement = () => wrapper.findByTestId('content-editor');
  const findEditorContent = () => wrapper.findComponent(EditorContent);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

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

  it('renders content_editor_error component', () => {
    createWrapper();

    expect(wrapper.findComponent(ContentEditorError).exists()).toBe(true);
  });

  describe('when loading content', () => {
    beforeEach(async () => {
      createWrapper();

      contentEditor.emit(LOADING_CONTENT_EVENT);

      await nextTick();
    });

    it('displays loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('hides EditorContent component', () => {
      expect(findEditorContent().exists()).toBe(false);
    });
  });

  describe('when loading content succeeds', () => {
    beforeEach(async () => {
      createWrapper();

      contentEditor.emit(LOADING_CONTENT_EVENT);
      await nextTick();
      contentEditor.emit(LOADING_SUCCESS_EVENT);
      await nextTick();
    });

    it('hides loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays EditorContent component', () => {
      expect(findEditorContent().exists()).toBe(true);
    });
  });

  describe('when loading content fails', () => {
    const error = 'error';

    beforeEach(async () => {
      createWrapper();

      contentEditor.emit(LOADING_CONTENT_EVENT);
      await nextTick();
      contentEditor.emit(LOADING_ERROR_EVENT, error);
      await nextTick();
    });

    it('hides loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays EditorContent component', () => {
      expect(findEditorContent().exists()).toBe(true);
    });
  });
});
