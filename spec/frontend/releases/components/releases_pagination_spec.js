import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReleasesPagination from '~/releases/components/releases_pagination.vue';
import ReleasesPaginationGraphql from '~/releases/components/releases_pagination_graphql.vue';
import ReleasesPaginationRest from '~/releases/components/releases_pagination_rest.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_pagination.vue', () => {
  let wrapper;

  const createComponent = useGraphQLEndpoint => {
    const store = new Vuex.Store({
      getters: {
        useGraphQLEndpoint: () => useGraphQLEndpoint,
      },
    });

    wrapper = shallowMount(ReleasesPagination, { store, localVue });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findRestPagination = () => wrapper.find(ReleasesPaginationRest);
  const findGraphQlPagination = () => wrapper.find(ReleasesPaginationGraphql);

  describe('when one of necessary feature flags is disabled', () => {
    beforeEach(() => {
      createComponent(false);
    });

    it('renders the REST pagination component', () => {
      expect(findRestPagination().exists()).toBe(true);
      expect(findGraphQlPagination().exists()).toBe(false);
    });
  });

  describe('when all the necessary feature flags are enabled', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('renders the GraphQL pagination component', () => {
      expect(findGraphQlPagination().exists()).toBe(true);
      expect(findRestPagination().exists()).toBe(false);
    });
  });
});
