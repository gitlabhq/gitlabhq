import { GlSkeletonLoader } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import AiCatalogAgents from '~/ai/catalog/pages/ai_catalog_agents.vue';

describe('AiCatalogAgents', () => {
  let wrapper;

  const mockAgentsData = [
    {
      id: 1,
      name: 'Test Agent 1',
      description: 'Description for agent 1',
    },
    {
      id: 2,
      name: 'Test Agent 2',
      description: 'Description for agent 2',
    },
    {
      id: 3,
      name: 'Test Agent 3',
      description: 'Description for agent 3',
    },
  ];

  const emptyAgentsData = [];

  const createComponent = ({ loading = false, mockData = mockAgentsData } = {}) => {
    wrapper = shallowMountExtended(AiCatalogAgents, {
      data() {
        return { aiCatalogAgents: mockData };
      },
      mocks: {
        $apollo: {
          queries: {
            aiCatalogAgents: {
              loading,
            },
          },
        },
      },
    });

    return waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllParagraphs = () => wrapper.findAll('p');

  describe('loading state', () => {
    it('shows skeleton loader when loading', () => {
      createComponent({ loading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findAllParagraphs()).toHaveLength(0);
    });

    it('does not show agent content when loading', () => {
      createComponent({ loading: true });

      expect(findAllParagraphs()).toHaveLength(0);
    });
  });

  describe('with agent data', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('displays agent names and descriptions correctly', () => {
      const paragraphs = findAllParagraphs();

      // Should have 6 paragraphs total (2 per agent: name and description)
      expect(paragraphs).toHaveLength(6);

      // Check agent names (even indices: 0, 2, 4)
      expect(paragraphs.at(0).text()).toBe('Test Agent 1');
      expect(paragraphs.at(2).text()).toBe('Test Agent 2');
      expect(paragraphs.at(4).text()).toBe('Test Agent 3');

      // Check agent descriptions (odd indices: 1, 3, 5)
      expect(paragraphs.at(1).text()).toBe('Description for agent 1');
      expect(paragraphs.at(3).text()).toBe('Description for agent 2');
      expect(paragraphs.at(5).text()).toBe('Description for agent 3');
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('with empty agent data', () => {
    beforeEach(async () => {
      await createComponent({ mockData: emptyAgentsData });
    });

    it('renders no agent paragraphs', () => {
      expect(findAllParagraphs()).toHaveLength(0);
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
