import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButtonGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DesignNavigation from '~/design_management/components/toolbar/design_navigation.vue';
import { DESIGN_ROUTE_NAME } from '~/design_management/router/constants';
import { Mousetrap } from '~/lib/mousetrap';
import getDesignListQuery from 'shared_queries/design_management/get_design_list.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getDesignListQueryResponse,
  designListQueryResponseNodes,
} from '../../mock_data/apollo_mock';

const push = jest.fn();
const $router = {
  push,
};

const $route = {
  path: '/designs/design-2',
  query: {},
};

describe('Design management pagination component', () => {
  let wrapper;

  const buildMockHandler = (nodes = designListQueryResponseNodes) => {
    return jest.fn().mockResolvedValue(getDesignListQueryResponse({ designs: nodes }));
  };

  const createMockApolloProvider = (handler) => {
    Vue.use(VueApollo);

    return createMockApollo([[getDesignListQuery, handler]]);
  };

  function createComponent({ propsData = {}, handler = buildMockHandler() } = {}) {
    wrapper = shallowMount(DesignNavigation, {
      propsData: {
        id: '2',
        ...propsData,
      },
      apolloProvider: createMockApolloProvider(handler),
      mocks: {
        $router,
        $route,
      },
    });
  }

  const findGlButtonGroup = () => wrapper.findComponent(GlButtonGroup);

  it('hides components when designs are empty', async () => {
    createComponent({ handler: buildMockHandler([]) });
    await waitForPromises();

    expect(findGlButtonGroup().exists()).toBe(false);
  });

  it('renders navigation buttons', async () => {
    createComponent({ handler: buildMockHandler() });
    await waitForPromises();

    expect(findGlButtonGroup().exists()).toBe(true);
  });

  describe('keyboard buttons navigation', () => {
    it('routes to previous design on Left button', async () => {
      createComponent({ propsData: { id: designListQueryResponseNodes[1].filename } });
      await waitForPromises();

      Mousetrap.trigger('left');
      expect(push).toHaveBeenCalledWith({
        name: DESIGN_ROUTE_NAME,
        params: { id: designListQueryResponseNodes[0].filename },
        query: {},
      });
    });

    it('routes to next design on Right button', async () => {
      createComponent({ propsData: { id: designListQueryResponseNodes[1].filename } });
      await waitForPromises();

      Mousetrap.trigger('right');
      expect(push).toHaveBeenCalledWith({
        name: DESIGN_ROUTE_NAME,
        params: { id: designListQueryResponseNodes[2].filename },
        query: {},
      });
    });
  });
});
