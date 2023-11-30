import { shallowMount } from '@vue/test-utils';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MODEL_VERSION } from '../mock_data';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(ShowMlModelVersion, { propsData: { modelVersion: MODEL_VERSION } });
};

const findTitleArea = () => wrapper.findComponent(TitleArea);
const findModelVersionDetail = () => wrapper.findComponent(ModelVersionDetail);

describe('ml/model_registry/apps/show_model_version.vue', () => {
  beforeEach(() => createWrapper());

  it('renders the title', () => {
    expect(findTitleArea().props('title')).toBe('blah / 1.2.3');
  });

  it('renders the model version detail', () => {
    expect(findModelVersionDetail().props('modelVersion')).toBe(MODEL_VERSION);
  });
});
