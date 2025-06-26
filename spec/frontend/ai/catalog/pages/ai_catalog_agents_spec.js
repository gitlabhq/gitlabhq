import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import AiCatalogAgents from '~/ai/catalog/pages/ai_catalog_agents.vue';
import AiCatalogList from '~/ai/catalog/components/ai_catalog_list.vue';

describe('AiCatalogAgents', () => {
  let wrapper;

  const mockAgentsData = [
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

  const findAiCatalogList = () => wrapper.findComponent(AiCatalogList);

  describe('component rendering', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders AiCatalogList component', () => {
      const catalogList = findAiCatalogList();

      expect(catalogList.exists()).toBe(true);
    });

    it('passes correct props to AiCatalogList', () => {
      const catalogList = findAiCatalogList();

      expect(catalogList.props('items')).toEqual(mockAgentsData);
      expect(catalogList.props('isLoading')).toBe(false);
    });
  });

  describe('loading state', () => {
    beforeEach(async () => {
      await createComponent({ loading: true });
    });

    it('passes loading state to AiCatalogList', () => {
      const catalogList = findAiCatalogList();

      expect(catalogList.props('isLoading')).toBe(true);
    });
  });

  describe('with agent data', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('passes agent data to AiCatalogList', () => {
      const catalogList = findAiCatalogList();

      expect(catalogList.props('items')).toEqual(mockAgentsData);
      expect(catalogList.props('items')).toHaveLength(3);
    });

    it('passes isLoading as false when not loading', () => {
      const catalogList = findAiCatalogList();

      expect(catalogList.props('isLoading')).toBe(false);
    });
  });
});
