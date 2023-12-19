import { GlSprintf, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SnippetDescription from '~/snippets/components/snippet_description_view.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import SnippetTitle from '~/snippets/components/snippet_title.vue';

describe('Snippet title component', () => {
  let wrapper;
  const title = 'The property of Thor';
  const description = 'Do not touch this hammer';
  const descriptionHtml = `<h2>${description}</h2>`;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(SnippetTitle, {
      propsData: {
        snippet: {
          title,
          description,
          descriptionHtml,
        },
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  }

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => getBinding(findIcon().element, 'gl-tooltip');

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders itself', () => {
      expect(wrapper.find('.snippet-header').exists()).toBe(true);
    });

    it('does not render spam icon when author is not banned', () => {
      expect(findIcon().exists()).toBe(false);
    });

    it('renders snippets title and description', () => {
      expect(wrapper.text().trim()).toContain(title);
      expect(wrapper.findComponent(SnippetDescription).props('description')).toBe(descriptionHtml);
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

  describe('when author is snippet is banned', () => {
    it('renders spam icon and tooltip when author is banned', () => {
      createComponent({
        propsData: {
          snippet: {
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
  });
});
