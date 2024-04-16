import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SearchableList from '~/ml/model_registry/components/searchable_list.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { BASE_SORT_FIELDS } from '~/ml/model_registry/constants';
import * as urlHelpers from '~/lib/utils/url_utility';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import { defaultPageInfo } from '../mock_data';

describe('ml/model_registry/components/searchable_list.vue', () => {
  let wrapper;

  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findByTestId('empty-state-slot');
  const findFirstRow = () => wrapper.findByTestId('element');
  const findRows = () => wrapper.findAllByTestId('element');
  const findSearch = () => wrapper.findComponent(RegistrySearch);

  const expectedFirstPage = {
    after: 'eyJpZCI6IjIifQ',
    first: 30,
    last: null,
    orderBy: 'created_at',
    sort: 'desc',
  };

  const defaultProps = {
    items: ['a', 'b', 'c'],
    pageInfo: defaultPageInfo,
    isLoading: false,
    errorMessage: '',
    showSearch: false,
    sortableFields: [],
  };

  const mountComponent = (props = {}) => {
    wrapper = shallowMountExtended(SearchableList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        RegistryList,
      },
      slots: {
        'empty-state': '<div data-testid="empty-state-slot">This is empty</div>',
        item: '<div data-testid="element"></div>',
      },
    });
  };

  describe('when list is loaded and has no data', () => {
    beforeEach(() => mountComponent({ items: [] }));

    it('shows empty state', () => {
      expect(findEmptyState().text()).toBe('This is empty');
    });

    it('does not display loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(false);
    });

    it('does not display rows', () => {
      expect(findFirstRow().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('Does not display error message', () => {
      expect(findLoadOrErrorOrShow().props('errorMessage')).toBe('');
    });
  });

  describe('if errorMessage', () => {
    beforeEach(() => mountComponent({ errorMessage: 'Failure!' }));

    it('shows error message', () => {
      expect(findLoadOrErrorOrShow().props('errorMessage')).toContain('Failure!');
    });
  });

  describe('if loading', () => {
    beforeEach(() => mountComponent({ isLoading: true }));

    it('shows loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(true);
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(() => mountComponent());

    it('displays package registry list', () => {
      expect(findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(findRegistryList().props()).toMatchObject({
        items: ['a', 'b', 'c'],
        isLoading: false,
        pagination: defaultPageInfo,
        hiddenDelete: true,
      });
    });

    it('displays package version rows', () => {
      expect(findRows().exists()).toEqual(true);
      expect(findRows()).toHaveLength(3);
    });

    it('does not display loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(false);
    });

    it('does not display empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    beforeEach(() => mountComponent());

    it('when it is created emits fetch-page to get first page', () => {
      mountComponent({ showSearch: true, sortableFields: BASE_SORT_FIELDS });

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage]]);
    });

    it('when list emits next-page emits fetchPage with correct pageInfo', () => {
      findRegistryList().vm.$emit('next-page');

      const expectedNewPageInfo = {
        after: 'eyJpZCI6IjIifQ',
        first: 30,
        last: null,
        orderBy: 'created_at',
        sort: 'desc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage], [expectedNewPageInfo]]);
    });

    it('when list emits prev-page emits fetchPage with correct pageInfo', () => {
      findRegistryList().vm.$emit('prev-page');

      const expectedNewPageInfo = {
        before: 'eyJpZCI6IjE2In0',
        first: null,
        last: 30,
        orderBy: 'created_at',
        sort: 'desc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage], [expectedNewPageInfo]]);
    });
  });

  describe('search', () => {
    beforeEach(() => {
      jest.spyOn(urlHelpers, 'updateHistory').mockImplementation(() => {});
    });

    it('does not show search bar when showSearch is false', () => {
      mountComponent({ showSearch: false });

      expect(findSearch().exists()).toBe(false);
    });

    it('mounts search correctly', () => {
      mountComponent({ showSearch: true, sortableFields: BASE_SORT_FIELDS });

      expect(findSearch().props()).toMatchObject({
        filters: [],
        sorting: {
          orderBy: 'created_at',
          sort: 'desc',
        },
        sortableFields: BASE_SORT_FIELDS,
      });
    });

    it('on search submit, emits fetch-page with correct variables', () => {
      mountComponent({ showSearch: true, sortableFields: BASE_SORT_FIELDS });

      findSearch().vm.$emit('filter:submit');

      const expectedVariables = {
        orderBy: 'created_at',
        sort: 'desc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage], [expectedVariables]]);
    });

    it('on sorting changed, emits fetch-page with correct variables', () => {
      mountComponent({ showSearch: true, sortableFields: BASE_SORT_FIELDS });

      const orderBy = 'name';
      findSearch().vm.$emit('sorting:changed', { orderBy });

      const expectedVariables = {
        orderBy: 'name',
        sort: 'desc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage], [expectedVariables]]);
    });

    it('on direction changed, emits fetch-page with correct variables', () => {
      mountComponent({ showSearch: true, sortableFields: BASE_SORT_FIELDS });

      const sort = 'asc';
      findSearch().vm.$emit('sorting:changed', { sort });

      const expectedVariables = {
        orderBy: 'created_at',
        sort: 'asc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage], [expectedVariables]]);
    });
  });
});
