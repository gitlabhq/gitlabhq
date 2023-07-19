import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlModelsIndexApp from '~/ml/model_registry/routes/models/index';
import { TITLE_LABEL } from '~/ml/model_registry/routes/models/index/translations';
import { mockModels } from './mock_data';

let wrapper;
const createWrapper = (models = mockModels) => {
  wrapper = shallowMountExtended(MlModelsIndexApp, {
    propsData: { models },
  });
};

const findModelLink = (index) => wrapper.findAllComponents(GlLink).at(index);
const modelLinkText = (index) => findModelLink(index).text();
const modelLinkHref = (index) => findModelLink(index).attributes('href');
const findTitle = () => wrapper.findByText(TITLE_LABEL);

describe('MlModelsIndex', () => {
  beforeEach(() => {
    createWrapper();
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
});
