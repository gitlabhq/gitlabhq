import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlModelsIndexApp from '~/ml/model_registry/routes/models/index';
import { TITLE_LABEL, NO_MODELS_LABEL } from '~/ml/model_registry/routes/models/index/translations';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import { mockModels, startCursor, defaultPageInfo } from './mock_data';

let wrapper;
const createWrapper = (propsData = { models: mockModels, pageInfo: defaultPageInfo }) => {
  wrapper = shallowMountExtended(MlModelsIndexApp, { propsData });
};

const findModelLink = (index) => wrapper.findAllComponents(GlLink).at(index);
const findPagination = () => wrapper.findComponent(Pagination);
const modelLinkText = (index) => findModelLink(index).text();
const modelLinkHref = (index) => findModelLink(index).attributes('href');
const findTitle = () => wrapper.findByText(TITLE_LABEL);
const findEmptyLabel = () => wrapper.findByText(NO_MODELS_LABEL);

describe('MlModelsIndex', () => {
  describe('empty state', () => {
    beforeEach(() => createWrapper({ models: [], pageInfo: defaultPageInfo }));

    it('displays empty state when no experiment', () => {
      expect(findEmptyLabel().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
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

    describe('model list', () => {
      it('displays the models', () => {
        expect(modelLinkHref(0)).toBe(mockModels[0].path);
        expect(modelLinkText(0)).toBe(`${mockModels[0].name} / ${mockModels[0].version}`);

        expect(modelLinkHref(1)).toBe(mockModels[1].path);
        expect(modelLinkText(1)).toBe(`${mockModels[1].name} / ${mockModels[1].version}`);
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
