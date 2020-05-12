import SnippetTitle from '~/snippets/components/snippet_title.vue';
import SnippetDescription from '~/snippets/components/snippet_description_view.vue';
import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

describe('Snippet header component', () => {
  let wrapper;
  const title = 'The property of Thor';
  const description = 'Do not touch this hammer';
  const descriptionHtml = `<h2>${description}</h2>`;
  const snippet = {
    snippet: {
      title,
      description,
      descriptionHtml,
    },
  };

  function createComponent({ props = snippet } = {}) {
    const defaultProps = { ...props };

    wrapper = shallowMount(SnippetTitle, {
      propsData: {
        ...defaultProps,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.snippet-header').exists()).toBe(true);
  });

  it('renders snippets title and description', () => {
    createComponent();

    expect(wrapper.text().trim()).toContain(title);
    expect(wrapper.find(SnippetDescription).props('description')).toBe(descriptionHtml);
  });

  it('does not render recent changes time stamp if there were no updates', () => {
    createComponent();
    expect(wrapper.find(GlSprintf).exists()).toBe(false);
  });

  it('does not render recent changes time stamp if the time for creation and updates match', () => {
    const props = Object.assign(snippet, {
      snippet: {
        ...snippet.snippet,
        createdAt: '2019-12-16T21:45:36Z',
        updatedAt: '2019-12-16T21:45:36Z',
      },
    });
    createComponent({ props });

    expect(wrapper.find(GlSprintf).exists()).toBe(false);
  });

  it('renders translated string with most recent changes timestamp if changes were made', () => {
    const props = Object.assign(snippet, {
      snippet: {
        ...snippet.snippet,
        createdAt: '2019-12-16T21:45:36Z',
        updatedAt: '2019-15-16T21:45:36Z',
      },
    });
    createComponent({ props });

    expect(wrapper.find(GlSprintf).exists()).toBe(true);
  });
});
