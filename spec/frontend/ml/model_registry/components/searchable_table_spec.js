import { GlTable } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SearchableTable from '~/ml/model_registry/components/searchable_table.vue';
import ModelVersionsTable from '~/ml/model_registry/components/model_versions_table.vue';
import ModelsTable from '~/ml/model_registry/components/models_table.vue';
import CandidatesTable from '~/ml/model_registry/components/candidates_table.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { BASE_SORT_FIELDS } from '~/ml/model_registry/constants';
import * as urlHelpers from '~/lib/utils/url_utility';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import { defaultPageInfo } from '../mock_data';
import { graphqlModelVersions, graphqlModels, graphqlCandidates } from '../graphql_mock_data';

describe('ml/model_registry/components/searchable_table.vue', () => {
  let wrapper;

  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findModelsTable = () => wrapper.findComponent(ModelsTable);
  const findCandidatesTable = () => wrapper.findComponent(CandidatesTable);
  const findModelVersionsTable = () => wrapper.findComponent(ModelVersionsTable);
  const findSearchableTable = () => wrapper.findComponent(SearchableTable);
  const findEmptyState = () => wrapper.findByTestId('empty-state-slot');
  const findRows = () => wrapper.findComponent(GlTable);
  const findSearch = () => wrapper.findComponent(RegistrySearch);

  const expectedFirstPage = {
    after: 'eyJpZCI6IjIifQ',
    first: 30,
    last: null,
    orderBy: 'created_at',
    sort: 'desc',
  };

  const defaultProps = {
    pageInfo: defaultPageInfo,
    isLoading: false,
    errorMessage: '',
    showSearch: false,
    sortableFields: [],
  };

  const mountComponent = (props = {}) => {
    wrapper = shallowMountExtended(SearchableTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlTable,
      },
      slots: {
        'empty-state': '<div data-testid="empty-state-slot">This is empty</div>',
        item: '<div data-testid="element"></div>',
      },
    });
  };

  describe('when list is loaded and has no data', () => {
    beforeEach(() => mountComponent({ modelVersions: [], models: [] }));

    it('shows empty state', () => {
      expect(findEmptyState().text()).toBe('This is empty');
    });

    it('does not display loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(false);
    });

    it('does not display rows', () => {
      expect(findRows().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(findModelVersionsTable().exists()).toBe(false);
      expect(findModelsTable().exists()).toBe(false);
      expect(findCandidatesTable().exists()).toBe(false);
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

  describe('when list is loaded with modelVersions', () => {
    beforeEach(() => mountComponent({ modelVersions: graphqlModelVersions }));

    it('displays model versions table', () => {
      expect(findModelVersionsTable().exists()).toBe(true);
      expect(findModelsTable().exists()).toBe(false);
      expect(findCandidatesTable().exists()).toBe(false);
    });

    it('binds the right props', () => {
      expect(findSearchableTable().props()).toMatchObject({
        modelVersions: graphqlModelVersions,
        isLoading: false,
        pageInfo: defaultPageInfo,
        showSearch: false,
        sortableFields: [],
      });
    });

    it('displays model version rows', () => {
      expect(findModelVersionsTable().props('items')).toHaveLength(2);
    });

    it('does not display loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(false);
    });

    it('does not display empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when list is loaded with models', () => {
    beforeEach(() => mountComponent({ models: graphqlModels }));

    it('displays model table', () => {
      expect(findModelsTable().exists()).toBe(true);
      expect(findModelVersionsTable().exists()).toBe(false);
      expect(findCandidatesTable().exists()).toBe(false);
    });

    it('binds the right props', () => {
      expect(findSearchableTable().props()).toMatchObject({
        models: graphqlModels,
        isLoading: false,
        pageInfo: defaultPageInfo,
        showSearch: false,
        sortableFields: [],
      });
    });

    it('displays model version rows', () => {
      expect(findModelsTable().props('items')).toHaveLength(1);
    });

    it('does not display loader', () => {
      expect(findLoadOrErrorOrShow().props('isLoading')).toBe(false);
    });

    it('does not display empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when list is loaded with candidates', () => {
    beforeEach(() => mountComponent({ candidates: graphqlCandidates }));

    it('displays candidates table', () => {
      expect(findCandidatesTable().exists()).toBe(true);
      expect(findModelVersionsTable().exists()).toBe(false);
      expect(findModelsTable().exists()).toBe(false);
    });

    it('binds the right props', () => {
      expect(findSearchableTable().props()).toMatchObject({
        candidates: graphqlCandidates,
        isLoading: false,
        pageInfo: defaultPageInfo,
        showSearch: false,
        sortableFields: [],
      });
    });

    it('displays candidate rows', () => {
      expect(findCandidatesTable().props('items')).toHaveLength(2);
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

    describe('when list emits next-page', () => {
      beforeEach(() => mountComponent());

      it('emits fetchPage with correct pageInfo', () => {
        findSearchableTable().vm.$emit('next-page');

        const expectedNewPageInfo = {
          after: 'eyJpZCI6IjIifQ',
          first: 30,
          last: null,
          orderBy: 'created_at',
          sort: 'desc',
        };

        expect(wrapper.emitted('fetch-page')[0]).toEqual([expectedFirstPage]);
        expect(wrapper.emitted('fetch-page')[0]).toEqual([expectedNewPageInfo]);
      });
    });

    it('when list emits next-page emits fetchPage with correct pageInfo', () => {
      findSearchableTable().vm.$emit('nextPage');

      const expectedNewPageInfo = {
        after: 'eyJpZCI6IjIifQ',
        first: 30,
        last: null,
        orderBy: 'created_at',
        sort: 'desc',
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedNewPageInfo]]);
    });

    it('when list emits prev-page emits fetchPage with correct pageInfo', () => {
      findSearchableTable().vm.$emit('prev-page');

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedFirstPage]]);
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
