import { shallowMount } from '@vue/test-utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import AiCatalogAgentsShow from '~/ai/catalog/pages/ai_catalog_agents_show.vue';

describe('AiCatalogAgentsShow', () => {
  let wrapper;

  const agentId = 732;

  const mockRouter = {
    push: jest.fn(),
  };

  const createComponent = () => {
    wrapper = shallowMount(AiCatalogAgentsShow, {
      mocks: {
        $route: {
          params: { id: agentId },
        },
        $router: mockRouter,
      },
    });
  };

  const findHeader = () => wrapper.findComponent(PageHeading);

  describe('component initialization', () => {
    it('renders the page heading', async () => {
      await createComponent();

      expect(findHeader().props('heading')).toBe(`Edit agent: ${agentId}`);
    });
  });
});
