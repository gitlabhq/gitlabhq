import { shallowMount } from '@vue/test-utils';
import { ShowMlModel } from '~/ml/model_registry/apps';
import { MODEL } from '../mock_data';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(ShowMlModel, { propsData: { model: MODEL } });
};

describe('ShowMlModel', () => {
  beforeEach(() => createWrapper());
  it('renders the app', () => {
    expect(wrapper.text()).toContain(MODEL.name);
  });
});
