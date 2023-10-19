import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlModelsIndexApp from '~/ml/model_registry/routes/models/index';
import ModelRow from '~/ml/model_registry/routes/models/index/components/model_row.vue';
import { TITLE_LABEL, NO_MODELS_LABEL } from '~/ml/model_registry/routes/models/index/translations';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import SearchBar from '~/ml/model_registry/routes/models/index/components/search_bar.vue';
import { BASE_SORT_FIELDS } from '~/ml/model_registry/routes/models/index/constants';
import { mockModels, startCursor, defaultPageInfo } from './mock_data';

let wrapper;
const createWrapper = (propsData = { models: mockModels, pageInfo: defaultPageInfo }) => {
  wrapper = shallowMountExtended(MlModelsIndexApp, { propsData });
};

const findModelRow = (index) => wrapper.findAllComponents(ModelRow).at(index);
const findPagination = () => wrapper.findComponent(Pagination);
const findTitle = () => wrapper.findByText(TITLE_LABEL);
const findEmptyLabel = () => wrapper.findByText(NO_MODELS_LABEL);
const findSearchBar = () => wrapper.findComponent(SearchBar);

describe('MlModelsIndex', () => {
  describe('empty state', () => {
    beforeEach(() => createWrapper({ models: [], pageInfo: defaultPageInfo }));

    it('displays empty state when no experiment', () => {
      expect(findEmptyLabel().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });

    it('does not show search bar', () => {
      expect(findSearchBar().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not show empty state', () => {
      expect(findEmptyLabel().exists()).toBe(false);
    });

    describe('header', () => {
      it('displays the title', () => {
        expect(findTitle().exists()).toBe(true);
      });
    });

    it('adds a search bar', () => {
      expect(findSearchBar().props()).toMatchObject({ sortableFields: BASE_SORT_FIELDS });
    });

    describe('model list', () => {
      it('displays the models', () => {
        expect(findModelRow(0).props('model')).toMatchObject(mockModels[0]);
        expect(findModelRow(1).props('model')).toMatchObject(mockModels[1]);
      });
    });

    describe('pagination', () => {
      it('should show', () => {
        expect(findPagination().exists()).toBe(true);
      });

      it('passes pagination to pagination component', () => {
        expect(findPagination().props('startCursor')).toBe(startCursor);
      });
    });
  });
});
