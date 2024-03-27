import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SnippetDescription from '~/snippets/components/snippet_description.vue';
import SnippetDescriptionView from '~/snippets/components/snippet_description_view.vue';

describe('Snippet description component', () => {
  let wrapper;
  const description = 'Do not touch this hammer';
  const descriptionHtml = `<h2>${description}</h2>`;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(SnippetDescription, {
      propsData: {
        snippet: {
          description,
          descriptionHtml,
        },
        ...propsData,
      },
    });
  }

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders itself', () => {
      expect(wrapper.find('[data-testid="snippet-description"]').exists()).toBe(true);
    });

    it('renders snippets description', () => {
      expect(wrapper.findComponent(SnippetDescriptionView).props('description')).toBe(
        descriptionHtml,
      );
    });

    it('does not render recent changes time stamp if there were no updates', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('does not render recent changes time stamp if the time for creation and updates match', () => {
      createComponent({
        propsData: {
          snippet: {
            createdAt: '2019-12-16T21:45:36Z',
            updatedAt: '2019-12-16T21:45:36Z',
          },
        },
      });

      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('renders translated string with most recent changes timestamp if changes were made', () => {
      createComponent({
        propsData: {
          snippet: {
            createdAt: '2019-12-16T21:45:36Z',
            updatedAt: '2019-15-16T21:45:36Z',
          },
        },
      });

      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });
  });
});
