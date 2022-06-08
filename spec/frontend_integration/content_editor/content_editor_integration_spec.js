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

  it('renders footnote ids alongside the footnote definition', async () => {
    buildWrapper();

    renderMarkdown.mockResolvedValue(`
    <p data-sourcepos="3:1-3:56" dir="auto">
      This reference tag is a mix of letters and numbers. <sup class="footnote-ref"><a href="#fn-footnote-2717" id="fnref-footnote-2717" data-footnote-ref="">2</a></sup>
    </p>
    <section class="footnotes" data-footnotes>
      <ol>
        <li id="fn-footnote-2717">
        <p data-sourcepos="6:7-6:31">This is another footnote. <a href="#fnref-footnote-2717" aria-label="Back to content" class="footnote-backref" data-footnote-backref=""><gl-emoji title="leftwards arrow with hook" data-name="leftwards_arrow_with_hook" data-unicode-version="1.1">↩</gl-emoji></a></p>
        </li>
      </ol>
    </section>
    `);

    await contentEditorService.setSerializedContent(`
    This reference tag is a mix of letters and numbers [^footnote].

    [^footnote]: This is another footnote.
    `);
    await nextTick();

    expect(wrapper.text()).toContain('footnote: This is another footnote');
  });
});
