import ModelCreate from '~/ml/model_registry/components/model_create.vue';
import NewMlModel from '~/ml/model_registry/apps/new_ml_model.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ml/model_registry/apps/new_ml_model.vue', () => {
  let wrapper;

  const mountComponent = (canWriteModelRegistry) => {
    wrapper = shallowMountExtended(NewMlModel, {
      propsData: {
        indexModelsPath: 'some/project/models',
        projectPath: 'project/path',
        maxAllowedFileSize: 1000,
        markdownPreviewPath: 'markdown/preview/path',
        canWriteModelRegistry,
      },
    });
  };

  const findModelCreate = () => wrapper.findComponent(ModelCreate);

  it('when user has no permission does not render the model create component', () => {
    mountComponent(false);

    expect(findModelCreate().exists()).toBe(false);
  });

  it('when user has permission renders the model create component', () => {
    mountComponent(true);

    expect(findModelCreate().exists()).toBe(true);
  });
});
