import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import { MODEL, makeModel } from '../mock_data';

let wrapper;

const createWrapper = (model = MODEL) => {
  wrapper = shallowMountExtended(ModelDetail, {
    propsData: { model },
    stubs: { GlTab },
  });
};

const findModelVersionDetail = () => wrapper.findComponent(ModelVersionDetail);
const findEmptyState = () => wrapper.findComponent(EmptyState);
const findVersionLink = () => wrapper.findByTestId('model-version-link');

describe('ShowMlModel', () => {
  describe('when it has latest version', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays the version', () => {
      expect(findModelVersionDetail().props('modelVersion')).toBe(MODEL.latestVersion);
    });

    it('displays a link to latest version', () => {
      expect(wrapper.text()).toContain('Latest version:');
      expect(findVersionLink().attributes('href')).toBe(MODEL.latestVersion.path);
      expect(findVersionLink().text()).toBe('1.2.3');
    });
  });

  describe('when it does not have latest version', () => {
    beforeEach(() => {
      createWrapper(makeModel({ latestVersion: null }));
    });

    it('shows empty state', () => {
      expect(findEmptyState().props('entityType')).toBe(MODEL_ENTITIES.modelVersion);
    });

    it('does not render model version detail', () => {
      expect(findModelVersionDetail().exists()).toBe(false);
    });
  });
});
