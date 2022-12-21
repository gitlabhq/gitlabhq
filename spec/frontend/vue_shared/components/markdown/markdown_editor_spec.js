import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { EDITING_MODE_MARKDOWN_FIELD, EDITING_MODE_CONTENT_EDITOR } from '~/vue_shared/constants';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/emoji');

describe('vue_shared/component/markdown/markdown_editor', () => {
  let wrapper;
  const value = 'test markdown';
  const renderMarkdownPath = '/api/markdown';
  const markdownDocsPath = '/help/markdown';
  const quickActionsDocsPath = '/help/quickactions';
  const enableAutocomplete = true;
  const enablePreview = false;
  const formFieldId = 'markdown_field';
  const formFieldName = 'form[markdown_field]';
  const formFieldPlaceholder = 'Write some markdown';
  const formFieldAriaLabel = 'Edit your content';
  let mock;

  const buildWrapper = ({ propsData = {}, attachTo, stubs = {} } = {}) => {
    wrapper = mountExtended(MarkdownEditor, {
      attachTo,
      propsData: {
        value,
        renderMarkdownPath,
        markdownDocsPath,
        quickActionsDocsPath,
        enableAutocomplete,
        enablePreview,
        formFieldId,
        formFieldName,
        formFieldPlaceholder,
        formFieldAriaLabel,
        ...propsData,
      },
      stubs: {
        BubbleMenu: stubComponent(BubbleMenu),
        ...stubs,
      },
    });
  };
  const findMarkdownField = () => wrapper.findComponent(MarkdownField);
  const findTextarea = () => wrapper.find('textarea');
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findContentEditor = () => wrapper.findComponent(ContentEditor);

  beforeEach(() => {
    window.uploads_path = 'uploads';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  it('displays markdown field by default', () => {
    buildWrapper({ propsData: { supportsQuickActions: true } });

    expect(findMarkdownField().props()).toEqual(
      expect.objectContaining({
        markdownPreviewPath: renderMarkdownPath,
        quickActionsDocsPath,
        canAttachFile: true,
        enableAutocomplete,
        textareaValue: value,
        markdownDocsPath,
        uploadsPath: window.uploads_path,
        enablePreview,
      }),
    );
  });

  it('renders markdown field textarea', () => {
    buildWrapper();

    expect(findTextarea().attributes()).toEqual(
      expect.objectContaining({
        id: formFieldId,
        name: formFieldName,
        placeholder: formFieldPlaceholder,
        'aria-label': formFieldAriaLabel,
      }),
    );

    expect(findTextarea().element.value).toBe(value);
  });

  it(`emits ${EDITING_MODE_CONTENT_EDITOR} event when enableContentEditor emitted from markdown editor`, () => {
    buildWrapper();

    findMarkdownField().vm.$emit('enableContentEditor');

    expect(wrapper.emitted(EDITING_MODE_CONTENT_EDITOR)).toHaveLength(1);
  });

  it(`emits ${EDITING_MODE_MARKDOWN_FIELD} event when enableMarkdownEditor emitted from content editor`, async () => {
    buildWrapper({
      stubs: { ContentEditor: stubComponent(ContentEditor) },
    });

    findMarkdownField().vm.$emit('enableContentEditor');

    await nextTick();

    findContentEditor().vm.$emit('enableMarkdownEditor');

    expect(wrapper.emitted(EDITING_MODE_MARKDOWN_FIELD)).toHaveLength(1);
  });

  describe(`when editingMode is ${EDITING_MODE_MARKDOWN_FIELD}`, () => {
    it('emits input event when markdown field textarea changes', async () => {
      buildWrapper();
      const newValue = 'new value';

      await findTextarea().setValue(newValue);

      expect(wrapper.emitted('input')).toEqual([[newValue]]);
    });

    describe('when autofocus is true', () => {
      beforeEach(async () => {
        buildWrapper({ attachTo: document.body, propsData: { autofocus: true } });

        await nextTick();
      });

      it('sets the markdown field as the active element in the document', () => {
        expect(document.activeElement).toBe(findTextarea().element);
      });
    });

    it('bubbles up keydown event', async () => {
      buildWrapper();

      await findTextarea().trigger('keydown');

      expect(wrapper.emitted('keydown')).toHaveLength(1);
    });

    describe(`when markdown field triggers enableContentEditor event`, () => {
      beforeEach(() => {
        buildWrapper();
        findMarkdownField().vm.$emit('enableContentEditor');
      });

      it('displays the content editor', () => {
        expect(findContentEditor().props()).toEqual(
          expect.objectContaining({
            renderMarkdown: expect.any(Function),
            uploadsPath: window.uploads_path,
            useBottomToolbar: false,
            markdown: value,
          }),
        );
      });

      it('adds hidden field with current markdown', () => {
        const hiddenField = wrapper.find(`#${formFieldId}`);

        expect(hiddenField.attributes()).toEqual(
          expect.objectContaining({
            id: formFieldId,
            name: formFieldName,
          }),
        );
        expect(hiddenField.element.value).toBe(value);
      });

      it('hides the markdown field', () => {
        expect(findMarkdownField().exists()).toBe(false);
      });

      it('updates localStorage value', () => {
        expect(findLocalStorageSync().props().value).toBe(EDITING_MODE_CONTENT_EDITOR);
      });
    });
  });

  describe(`when editingMode is ${EDITING_MODE_CONTENT_EDITOR}`, () => {
    beforeEach(() => {
      buildWrapper();
      findMarkdownField().vm.$emit('enableContentEditor');
    });

    describe('when autofocus is true', () => {
      beforeEach(() => {
        buildWrapper({
          propsData: { autofocus: true },
          stubs: { ContentEditor: stubComponent(ContentEditor) },
        });
      });

      it('sets the content editor autofocus property to end', () => {
        expect(findContentEditor().props().autofocus).toBe('end');
      });
    });

    it('emits input event when content editor emits change event', async () => {
      const newValue = 'new value';

      await findContentEditor().vm.$emit('change', { markdown: newValue });

      expect(wrapper.emitted('input')).toEqual([[newValue]]);
    });

    it('bubbles up keydown event', () => {
      const event = new Event('keydown');

      findContentEditor().vm.$emit('keydown', event);

      expect(wrapper.emitted('keydown')).toEqual([[event]]);
    });

    describe(`when richText editor triggers enableMarkdownEditor event`, () => {
      beforeEach(() => {
        findContentEditor().vm.$emit('enableMarkdownEditor');
      });

      it('hides the content editor', () => {
        expect(findContentEditor().exists()).toBe(false);
      });

      it('shows the markdown field', () => {
        expect(findMarkdownField().exists()).toBe(true);
      });

      it('updates localStorage value', () => {
        expect(findLocalStorageSync().props().value).toBe(EDITING_MODE_MARKDOWN_FIELD);
      });
    });
  });
});
