import { GlTab, GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import AiCatalogNavTabs from '~/ai/catalog/components/ai_catalog_nav_tabs.vue';
import { AI_CATALOG_AGENTS_ROUTE } from '~/ai/catalog/router/constants';

describe('AiCatalogNavTabs', () => {
  let wrapper;

  const mockRouter = {
    push: jest.fn(),
  };

  const createComponent = ({ routePath = '/ai/catalog' } = {}) => {
    wrapper = shallowMountExtended(AiCatalogNavTabs, {
      mocks: {
        $route: {
          path: routePath,
        },
        $router: mockRouter,
      },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);

  beforeEach(() => {
    createComponent();
  });

  it('renders tabs', () => {
    expect(findTabs().exists()).toBe(true);
  });

  it('renders the correct number of tabs', () => {
    expect(findAllTabs()).toHaveLength(1);
  });

  it('renders the Agents tab', () => {
    const agentsTab = findAllTabs().at(0);

    expect(agentsTab.attributes('title')).toBe('Agents');
  });

  describe('navigation', () => {
    it('navigates to the correct route when tab is clicked', () => {
      const agentsTab = findAllTabs().at(0);

      agentsTab.vm.$emit('click');

      expect(mockRouter.push).toHaveBeenCalledWith({ name: AI_CATALOG_AGENTS_ROUTE });
    });

    it('does not navigate if already on the same route', () => {
      createComponent({ routePath: AI_CATALOG_AGENTS_ROUTE });

      const agentsTab = findAllTabs().at(0);

      agentsTab.vm.$emit('click');

      expect(mockRouter.push).not.toHaveBeenCalled();
    });
  });
});
