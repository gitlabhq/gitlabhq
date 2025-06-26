import { GlSkeletonLoader } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import AiCatalogList from '~/ai/catalog/components/ai_catalog_list.vue';
import AiCatalogListItem from '~/ai/catalog/components/ai_catalog_list_item.vue';

describe('AiCatalogList', () => {
  let wrapper;

  const mockItems = [
    {
      id: 1,
      name: 'Test AI Agent 1',
      model: 'gpt-4',
      type: 'Assistant',
      version: 'v1.2.0',
      description: 'A helpful AI assistant for testing purposes',
      releasedAt: '2024-01-15T10:30:00Z',
      verified: true,
    },
    {
      id: 2,
      name: 'Test AI Agent 2',
      model: 'claude-3',
      type: 'Chatbot',
      version: 'v1.0.0',
      description: 'Another AI assistant',
      releasedAt: '2024-02-10T14:20:00Z',
      verified: false,
    },
    {
      id: 3,
      name: 'Test AI Agent 3',
      model: 'gemini-pro',
      type: 'Helper',
      version: 'v2.1.0',
      verified: true,
    },
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(AiCatalogList, {
      propsData: {
        items: mockItems,
        isLoading: false,
        ...props,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findList = () => wrapper.find('ul');
  const findListItems = () => wrapper.findAllComponents(AiCatalogListItem);
  const findContainer = () => wrapper.findByTestId('ai-catalog-list');

  describe('component rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the container with correct test id', () => {
      const container = findContainer();

      expect(container.exists()).toBe(true);
      expect(container.element.tagName).toBe('DIV');
    });

    it('renders list when not loading', () => {
      const list = findList();

      expect(list.exists()).toBe(true);
      expect(list.classes()).toContain('gl-list-style-none');
      expect(list.classes()).toContain('gl-m-0');
      expect(list.classes()).toContain('gl-p-0');
    });

    it('does not render skeleton loader when not loading', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('loading state', () => {
    it('shows skeleton loader and hides list when loading is true', () => {
      createComponent({ isLoading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findList().exists()).toBe(false);
    });

    it('shows list and hides skeleton loader when loading is false', () => {
      createComponent({ isLoading: false });

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findList().exists()).toBe(true);
    });
  });

  describe('list items rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correct number of list items', () => {
      const listItems = findListItems();

      expect(listItems).toHaveLength(3);
    });

    it('passes correct props to each list item', () => {
      const listItems = findListItems();

      listItems.wrappers.forEach((listItem, index) => {
        expect(listItem.props('item')).toEqual(mockItems[index]);
      });
    });
  });

  describe('empty items', () => {
    beforeEach(() => {
      createComponent({ items: [] });
    });

    it('renders empty list when no items provided', () => {
      expect(findList().exists()).toBe(true);
      expect(findListItems()).toHaveLength(0);
    });

    it('does not render skeleton loader when not loading with empty items', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
