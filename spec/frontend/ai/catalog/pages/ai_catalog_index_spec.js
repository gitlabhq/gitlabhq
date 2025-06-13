import { GlSkeletonLoader } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import AiCatalogIndex from '~/ai/catalog/pages/ai_catalog_index.vue';

describe('AiCatalogIndex', () => {
  let wrapper;

  const mockWorkflowsData = [
    {
      id: 1,
      name: 'Test Workflow 1',
      type: 'Type A',
    },
    {
      id: 2,
      name: 'Test Workflow 2',
      type: 'Type B',
    },
    {
      id: 3,
      name: 'Test Workflow 3',
      type: 'Type C',
    },
  ];

  const emptyWorkflowsData = [];

  const createComponent = ({ loading = false, mockData = mockWorkflowsData } = {}) => {
    wrapper = shallowMountExtended(AiCatalogIndex, {
      data() {
        return { userWorkflows: mockData };
      },
      mocks: {
        $apollo: {
          queries: {
            userWorkflows: {
              loading,
            },
          },
        },
      },
    });

    return waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTitle = () => wrapper.find('h1');
  const findAllParagraphs = () => wrapper.findAll('p');

  describe('component initialization', () => {
    it('renders the page title', async () => {
      await createComponent();

      expect(findTitle().text()).toBe('AI Catalog');
    });
  });

  describe('loading state', () => {
    it('shows skeleton loader when loading', () => {
      createComponent({ loading: true });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findAllParagraphs()).toHaveLength(0);
    });
  });

  describe('with workflow data', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('displays workflow names and types correctly', () => {
      const paragraphs = findAllParagraphs();

      // Should have 6 paragraphs total (2 per workflow: name and type)
      expect(paragraphs).toHaveLength(6);

      // Check workflow names (even indices: 0, 2, 4)
      expect(paragraphs.at(0).text()).toBe('Test Workflow 1');
      expect(paragraphs.at(2).text()).toBe('Test Workflow 2');
      expect(paragraphs.at(4).text()).toBe('Test Workflow 3');

      // Check workflow types (odd indices: 1, 3, 5)
      expect(paragraphs.at(1).text()).toBe('Type A');
      expect(paragraphs.at(3).text()).toBe('Type B');
      expect(paragraphs.at(5).text()).toBe('Type C');
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('with empty workflow data', () => {
    beforeEach(async () => {
      await createComponent({ mockData: emptyWorkflowsData });
    });

    it('renders no workflow paragraphs', () => {
      expect(findAllParagraphs()).toHaveLength(0);
    });

    it('does not show skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });
});
