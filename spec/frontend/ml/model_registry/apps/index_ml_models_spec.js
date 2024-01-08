import { GlBadge, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { IndexMlModels } from '~/ml/model_registry/apps';
import ModelRow from '~/ml/model_registry/components/model_row.vue';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import SearchBar from '~/ml/model_registry/components/search_bar.vue';
import { BASE_SORT_FIELDS, MODEL_ENTITIES } from '~/ml/model_registry/constants';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import { mockModels, startCursor, defaultPageInfo } from '../mock_data';

let wrapper;

const createWrapper = (propsData = {}) => {
  wrapper = shallowMountExtended(IndexMlModels, {
    propsData: {
      models: mockModels,
      pageInfo: defaultPageInfo,
      modelCount: 2,
      createModelPath: 'path/to/create',
      canWriteModelRegistry: false,
      ...propsData,
    },
  });
};

const findModelRow = (index) => wrapper.findAllComponents(ModelRow).at(index);
const findPagination = () => wrapper.findComponent(Pagination);
const findEmptyState = () => wrapper.findComponent(EmptyState);
const findSearchBar = () => wrapper.findComponent(SearchBar);
const findTitleArea = () => wrapper.findComponent(TitleArea);
const findModelCountMetadataItem = () => findTitleArea().findComponent(MetadataItem);
const findBadge = () => wrapper.findComponent(GlBadge);
const findCreateButton = () => findTitleArea().findComponent(GlButton);
const findActionsDropdown = () => wrapper.findComponent(ActionsDropdown);

describe('ml/model_registry/apps/index_ml_models', () => {
  describe('empty state', () => {
    beforeEach(() => createWrapper({ models: [], pageInfo: defaultPageInfo }));

    it('shows empty state', () => {
      expect(findEmptyState().props('entityType')).toBe(MODEL_ENTITIES.model);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });

    it('does not show search bar', () => {
      expect(findSearchBar().exists()).toBe(false);
    });

    it('renders the extra actions button', () => {
      expect(findActionsDropdown().exists()).toBe(true);
    });
  });

  describe('create button', () => {
    describe('when user has no permission to write model registry', () => {
      it('does not display create button', () => {
        createWrapper();

        expect(findCreateButton().exists()).toBe(false);
      });
    });

    describe('when user has permission to write model registry', () => {
      it('displays create button', () => {
        createWrapper({ canWriteModelRegistry: true });

        expect(findCreateButton().attributes().href).toBe('path/to/create');
      });
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not show empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
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
