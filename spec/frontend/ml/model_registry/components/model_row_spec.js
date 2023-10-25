import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelRow from '~/ml/model_registry/components/model_row.vue';
import { mockModels, modelWithoutVersion } from '../mock_data';

let wrapper;
const createWrapper = (model = mockModels[0]) => {
  wrapper = shallowMountExtended(ModelRow, { propsData: { model } });
};

const findLink = () => wrapper.findComponent(GlLink);
const findMessage = (message) => wrapper.findByText(message);

describe('ModelRow', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('Has a link to the model', () => {
    expect(findLink().text()).toBe(mockModels[0].name);
    expect(findLink().attributes('href')).toBe(mockModels[0].path);
  });

  it('Shows the latest version and the version count', () => {
    expect(findMessage('1.0 · 3 versions').exists()).toBe(true);
  });

  it('Shows the latest version and no version count if it has only 1 version', () => {
    createWrapper(mockModels[1]);

    expect(findMessage('1.1 · No other versions').exists()).toBe(true);
  });

  it('Shows no version message if model has no versions', () => {
    createWrapper(modelWithoutVersion);

    expect(findMessage('No registered versions').exists()).toBe(true);
  });
});
