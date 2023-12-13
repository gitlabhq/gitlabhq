import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';

let wrapper;
const createWrapper = (entityType) => {
  wrapper = shallowMount(EmptyState, { propsData: { entityType } });
};

const findEmptyState = () => wrapper.findComponent(GlEmptyState);

describe('ml/model_registry/components/empty_state.vue', () => {
  describe('when entity type is model', () => {
    beforeEach(() => {
      createWrapper(MODEL_ENTITIES.model);
    });

    it('shows the correct empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'Start tracking your machine learning models',
        description: 'Store and manage your machine learning models and versions',
        primaryButtonText: 'Add a model',
        primaryButtonLink:
          '/help/user/project/ml/model_registry/index#creating-machine-learning-models-and-model-versions',
        svgPath: 'file-mock',
      });
    });
  });

  describe('when entity type is model version', () => {
    beforeEach(() => {
      createWrapper(MODEL_ENTITIES.modelVersion);
    });

    it('shows the correct empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'Manage versions of your machine learning model',
        description: 'Use versions to track performance, parameters, and metadata',
        primaryButtonText: 'Create a model version',
        primaryButtonLink:
          '/help/user/project/ml/model_registry/index#creating-machine-learning-models-and-model-versions',
        svgPath: 'file-mock',
      });
    });
  });
});
