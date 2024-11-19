import ModelEdit from '~/ml/model_registry/components/model_edit.vue';
import EditMlModel from '~/ml/model_registry/apps/edit_ml_model.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ml/model_registry/apps/edit_ml_model.vue', () => {
  let wrapper;

  const mountComponent = (canWriteModelRegistry) => {
    wrapper = shallowMountExtended(EditMlModel, {
      propsData: {
        projectPath: 'project/path',
        canWriteModelRegistry,
        markdownPreviewPath: 'markdown/preview/path',
        modelPath: 'model/path',
        modelId: 1,
        modelName: 'GPT0',
        modelDescription: 'No desc',
      },
    });
  };

  const findModelEdit = () => wrapper.findComponent(ModelEdit);

  it('when user has no permission does not render the model edit component', () => {
    mountComponent(false);

    expect(findModelEdit().exists()).toBe(false);
  });

  it('when user has permission renders the model edit component', () => {
    mountComponent(true);

    expect(findModelEdit().props()).toEqual({
      projectPath: 'project/path',
      disableAttachments: false,
      model: { id: 1, name: 'GPT0', description: 'No desc' },
      modelPath: 'model/path',
      markdownPreviewPath: 'markdown/preview/path',
    });
  });
});
