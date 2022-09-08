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

  const buildWrapper = ({ markdown = '' } = {}) => {
    wrapper = mountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        uploadsPath: '/',
        markdown,
      },
    });
  };

  const waitUntilContentIsLoaded = async () => {
    await waitForPromises();
    await nextTick();
  };

  beforeEach(() => {
    renderMarkdown = jest.fn();
  });

  describe('when loading initial content', () => {
    describe('when the initial content is empty', () => {
      it('still hides the loading indicator', async () => {
        renderMarkdown.mockResolvedValue('');

        buildWrapper();

        await waitUntilContentIsLoaded();

        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });
    });

    describe('when the initial content is not empty', () => {
      const initialContent = '<p><strong>bold text</strong></p>';
      beforeEach(async () => {
        renderMarkdown.mockResolvedValue(initialContent);

        buildWrapper();

        await waitUntilContentIsLoaded();
      });
      it('hides the loading indicator', () => {
        expect(wrapper.findByTestId('content-editor-loading-indicator').exists()).toBe(false);
      });

      it('displays the initial content', async () => {
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
    jest.useFakeTimers();

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
});
