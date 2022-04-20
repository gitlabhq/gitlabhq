import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ContentEditor } from '~/content_editor';

/**
 * This spec exercises some workflows in the Content Editor without mocking
 * any component.
 *
 */
describe('content_editor', () => {
  let wrapper;
  let renderMarkdown;
  let contentEditorService;

  const buildWrapper = () => {
    renderMarkdown = jest.fn();
    wrapper = mountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        uploadsPath: '/',
      },
      listeners: {
        initialized(contentEditor) {
          contentEditorService = contentEditor;
        },
      },
    });
  };

  describe('when loading initial content', () => {
    describe('when the initial content is empty', () => {
      it('still hides the loading indicator', async () => {
        buildWrapper();

        renderMarkdown.mockResolvedValue('');

        await contentEditorService.setSerializedContent('');
        await nextTick();

        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });
    });

    describe('when the initial content is not empty', () => {
      const initialContent = '<p><strong>bold text</strong></p>';
      beforeEach(async () => {
        buildWrapper();

        renderMarkdown.mockResolvedValue(initialContent);

        await contentEditorService.setSerializedContent('**bold text**');
        await nextTick();
      });
      it('hides the loading indicator', async () => {
        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });

      it('displays the initial content', async () => {
        expect(wrapper.html()).toContain(initialContent);
      });
    });
  });
});
