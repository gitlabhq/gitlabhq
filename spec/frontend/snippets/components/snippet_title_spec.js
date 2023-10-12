import { GlSprintf, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import SnippetDescription from '~/snippets/components/snippet_description_view.vue';
import SnippetTitle from '~/snippets/components/snippet_title.vue';

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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  }

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => getBinding(findIcon().element, 'gl-tooltip');

  it('renders itself', () => {
    createComponent();
    expect(wrapper.find('.snippet-header').exists()).toBe(true);
  });

  it('does not render spam icon when author is not banned', () => {
    createComponent();
    expect(findIcon().exists()).toBe(false);
  });

  it('renders spam icon and tooltip when author is banned', () => {
    createComponent({
      props: {
        snippet: {
          ...snippet.snippet,
          hidden: true,
        },
      },
    });

    expect(findIcon().props()).toMatchObject({
      ariaLabel: 'Hidden',
      name: 'spam',
      size: 16,
    });

    expect(findIcon().attributes('title')).toBe(
      'This snippet is hidden because its author has been banned',
    );

    expect(findTooltip()).toBeDefined();
  });

  it('renders snippets title and description', () => {
    createComponent();

    expect(wrapper.text().trim()).toContain(title);
    expect(wrapper.findComponent(SnippetDescription).props('description')).toBe(descriptionHtml);
  });

  it('does not render recent changes time stamp if there were no updates', () => {
    createComponent();
    expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
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

    expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
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

    expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
  });
});
