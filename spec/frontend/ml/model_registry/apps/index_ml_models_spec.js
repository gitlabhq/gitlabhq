import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { IndexMlModels } from '~/ml/model_registry/apps';
import ModelRow from '~/ml/model_registry/components/model_row.vue';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import SearchBar from '~/ml/model_registry/components/search_bar.vue';
import { BASE_SORT_FIELDS } from '~/ml/model_registry/constants';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import { mockModels, startCursor, defaultPageInfo } from '../mock_data';

let wrapper;
const createWrapper = (
  propsData = { models: mockModels, pageInfo: defaultPageInfo, modelCount: 2 },
) => {
  wrapper = shallowMountExtended(IndexMlModels, { propsData });
};

const findModelRow = (index) => wrapper.findAllComponents(ModelRow).at(index);
const findPagination = () => wrapper.findComponent(Pagination);
const findEmptyLabel = () => wrapper.findByText('No models registered in this project');
const findSearchBar = () => wrapper.findComponent(SearchBar);
const findTitleArea = () => wrapper.findComponent(TitleArea);
const findModelCountMetadataItem = () => findTitleArea().findComponent(MetadataItem);
const findBadge = () => wrapper.findComponent(GlBadge);

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
        expect(findTitleArea().text()).toContain('Model registry');
      });

      it('displays the experiment badge', () => {
        expect(findBadge().attributes().href).toBe('/help/user/project/ml/model_registry/index.md');
      });

      it('sets model metadata item to model count', () => {
        expect(findModelCountMetadataItem().props('text')).toBe(`2 models`);
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
