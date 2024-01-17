import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelRow from '~/ml/model_registry/components/model_row.vue';
import { mockModels, modelWithoutVersion } from '../mock_data';

let wrapper;
const createWrapper = (model = mockModels[0]) => {
  wrapper = shallowMountExtended(ModelRow, { propsData: { model } });
};

const findTitleLink = () => wrapper.findAllComponents(GlLink).at(0);
const findVersionLink = () => wrapper.findAllComponents(GlLink).at(1);
const findMessage = (message) => wrapper.findByText(message);

describe('ModelRow', () => {
  it('Has a link to the model', () => {
    createWrapper();

    expect(findTitleLink().text()).toBe(mockModels[0].name);
    expect(findTitleLink().attributes('href')).toBe(mockModels[0].path);
  });

  it('Shows the latest version and the version count', () => {
    createWrapper();

    expect(findVersionLink().text()).toBe(mockModels[0].version);
    expect(findVersionLink().attributes('href')).toBe(mockModels[0].versionPath);
    expect(findMessage('· 3 versions').exists()).toBe(true);
  });

  it('Shows the latest version and no version count if it has only 1 version', () => {
    createWrapper(mockModels[1]);

    expect(findVersionLink().text()).toBe(mockModels[1].version);
    expect(findVersionLink().attributes('href')).toBe(mockModels[1].versionPath);

    expect(findMessage('· 1 version').exists()).toBe(true);
  });

  it('Shows no version message if model has no versions', () => {
    createWrapper(modelWithoutVersion);

    expect(findMessage('No registered versions').exists()).toBe(true);
  });
});
