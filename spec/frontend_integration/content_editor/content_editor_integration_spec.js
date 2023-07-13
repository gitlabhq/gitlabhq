import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ContentEditor } from '~/content_editor';
import waitForPromises from 'helpers/wait_for_promises';

/**
 * This spec exercises some workflows in the Content Editor without mocking
 * any component.
 *
 */
describe('content_editor', () => {
  let wrapper;
  let renderMarkdown;

  const buildWrapper = ({ markdown = '', listeners = {} } = {}) => {
    wrapper = mountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        uploadsPath: '/',
        markdown,
      },
      listeners: {
        ...listeners,
      },
      mocks: {
        $apollo: {
          queries: {
            currentUser: {
              loading: false,
            },
          },
        },
      },
    });
  };

  const waitUntilContentIsLoaded = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mockRenderMarkdownResponse = (response) => {
    renderMarkdown.mockImplementation((markdown) => (markdown ? response : null));
  };

  beforeEach(() => {
    renderMarkdown = jest.fn();
  });

  describe('when loading initial content', () => {
    describe('when the initial content is empty', () => {
      it('still hides the loading indicator', async () => {
        mockRenderMarkdownResponse('');

        buildWrapper();

        await waitUntilContentIsLoaded();

        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });
    });

    describe('when the initial content is not empty', () => {
      const initialContent = '<strong>bold text</strong> and <em>italic text</em>';
      beforeEach(async () => {
        mockRenderMarkdownResponse(initialContent);

        buildWrapper({
          markdown: '**bold text**',
        });

        await waitUntilContentIsLoaded();
      });
      it('hides the loading indicator', () => {
        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });

      it('displays the initial content', () => {
        expect(wrapper.html()).toContain(initialContent);
      });
    });
  });

  describe('when preserveUnchangedMarkdown feature flag is enabled', () => {
    beforeEach(() => {
      gon.features = { preserveUnchangedMarkdown: true };
    });
    afterEach(() => {
      gon.features = { preserveUnchangedMarkdown: false };
    });

    it('processes and renders footnote ids alongside the footnote definition', async () => {
      buildWrapper({
        markdown: `
This reference tag is a mix of letters and numbers [^footnote].

[^footnote]: This is another footnote.
        `,
      });

      await waitUntilContentIsLoaded();

      expect(wrapper.text()).toContain('footnote: This is another footnote');
    });

    it('processes and displays reference definitions', async () => {
      buildWrapper({
        markdown: `
[GitLab][gitlab]

[gitlab]: https://gitlab.com
        `,
      });

      await waitUntilContentIsLoaded();

      expect(wrapper.find('pre').text()).toContain('[gitlab]: https://gitlab.com');
    });
  });

  it('renders table of contents', async () => {
    renderMarkdown.mockResolvedValueOnce(`
<ul class="section-nav">
</ul>
<h1 dir="auto" data-sourcepos="3:1-3:11">
  Heading 1
</h1>
<h2 dir="auto" data-sourcepos="5:1-5:12">
  Heading 2
</h2>
    `);

    buildWrapper({
      markdown: `
[TOC]

# Heading 1

## Heading 2
      `,
    });

    await waitUntilContentIsLoaded();

    expect(wrapper.findByTestId('table-of-contents').text()).toContain('Heading 1');
    expect(wrapper.findByTestId('table-of-contents').text()).toContain('Heading 2');
  });

  describe('when pasting content', () => {
    const buildClipboardData = (data = {}) => ({
      clipboardData: {
        getData(mimeType) {
          return data[mimeType];
        },
        types: Object.keys(data),
      },
    });

    describe('when the clipboard does not contain text/html data', () => {
      it('processes the clipboard content as markdown', async () => {
        const processedMarkdown = '<strong>bold text</strong>';

        buildWrapper();

        await waitUntilContentIsLoaded();

        mockRenderMarkdownResponse(processedMarkdown);

        wrapper.find('[contenteditable]').trigger(
          'paste',
          buildClipboardData({
            'text/plain': '**bold text**',
          }),
        );

        await waitUntilContentIsLoaded();

        expect(wrapper.find('[contenteditable]').html()).toContain(processedMarkdown);
      });
    });
  });

  it('bubbles up the keydown event captured by ProseMirror', async () => {
    const keydownHandler = jest.fn();

    buildWrapper({ listeners: { keydown: keydownHandler } });

    await waitUntilContentIsLoaded();

    wrapper.find('[contenteditable]').trigger('keydown', {});

    expect(wrapper.emitted('keydown')).toHaveLength(1);
  });
});
