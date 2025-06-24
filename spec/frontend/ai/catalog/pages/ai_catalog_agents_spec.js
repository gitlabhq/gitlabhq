import { GlLink, GlSkeletonLoader } from '@gitlab/ui';

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
  const findAllListItems = () => wrapper.findAll('li');

  describe('loading state', () => {
    it('shows skeleton loader when loading', () => {
      createComponent({ loading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findAllListItems()).toHaveLength(0);
    });

    it('does not show agent content when loading', () => {
      createComponent({ loading: true });

      expect(findAllListItems()).toHaveLength(0);
    });
  });

  describe('with agent data', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('displays agent names and descriptions correctly', () => {
      const listItems = findAllListItems();

      expect(listItems).toHaveLength(3);

      const listItem0 = listItems.at(0);
      const listItem1 = listItems.at(1);
      const listItem2 = listItems.at(2);

      // Check agent names
      expect(listItem0.findComponent(GlLink).text()).toBe('Test Agent 1');
      expect(listItem1.findComponent(GlLink).text()).toBe('Test Agent 2');
      expect(listItem2.findComponent(GlLink).text()).toBe('Test Agent 3');

      // Check agent descriptions
      expect(listItem0.find('p').text()).toBe('Description for agent 1');
      expect(listItem1.find('p').text()).toBe('Description for agent 2');
      expect(listItem2.find('p').text()).toBe('Description for agent 3');
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('with empty agent data', () => {
    beforeEach(async () => {
      await createComponent({ mockData: emptyAgentsData });
    });

    it('renders no agent list items', () => {
      expect(findAllListItems()).toHaveLength(0);
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
