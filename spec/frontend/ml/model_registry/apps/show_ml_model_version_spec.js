import { shallowMount } from '@vue/test-utils';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';
import { MODEL_VERSION } from '../mock_data';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(ShowMlModelVersion, { propsData: { modelVersion: MODEL_VERSION } });
};

describe('ShowMlModelVersion', () => {
  beforeEach(() => createWrapper());
  it('renders the app', () => {
    expect(wrapper.text()).toContain(`${MODEL_VERSION.model.name} - ${MODEL_VERSION.version}`);
  });
});
