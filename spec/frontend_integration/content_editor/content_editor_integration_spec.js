import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import savedRepliesQuery from 'ee_else_ce/vue_shared/components/markdown/saved_replies.query.graphql';
import { ContentEditor } from '~/content_editor';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

/**
 * This spec exercises some workflows in the Content Editor without mocking
 * any component.
 *
 */
describe('content_editor', () => {
  let wrapper;
  let renderMarkdown;

  const buildWrapper = ({ markdown = '', listeners = {} } = {}) => {
    const apolloProvider = createMockApollo([
      [savedRepliesQuery, jest.fn().mockResolvedValue({ data: { currentUser: null } })],
    ]);

    wrapper = mountExtended(ContentEditor, {
      propsData: {
        markdownDocsPath: '',
        renderMarkdown,
        uploadsPath: '/',
        markdown,
        supportsTableOfContents: true,
      },
      listeners: {
        ...listeners,
      },
      apolloProvider,
    });
  };

  const waitUntilContentIsLoaded = async () => {
    await waitForPromises();
    await nextTick();
  };

  const mockRenderMarkdownResponse = (response) => {
    renderMarkdown.mockImplementation((markdown) => ({ body: markdown ? response : null }));
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

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
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
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      });

      it('displays the initial content', () => {
        expect(wrapper.html()).toContain(initialContent);
      });
    });
  });

  it('renders table of contents', async () => {
    renderMarkdown.mockResolvedValueOnce({
      body: `
<ul class="section-nav">
</ul>
<h1 dir="auto" data-sourcepos="3:1-3:11">
  Heading 1
</h1>
<h2 dir="auto" data-sourcepos="5:1-5:12">
  Heading 2
</h2>
    `,
    });

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

  it('bubbles up the keydown event captured by ProseMirror', async () => {
    const keydownHandler = jest.fn();

    buildWrapper({ listeners: { keydown: keydownHandler } });

    await waitUntilContentIsLoaded();

    wrapper.find('[contenteditable]').trigger('keydown', {});

    expect(wrapper.emitted('keydown')).toHaveLength(1);
  });
});
