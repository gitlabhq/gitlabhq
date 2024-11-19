import ModelVersionEdit from '~/ml/model_registry/components/model_version_edit.vue';
import EditMlModelVersion from '~/ml/model_registry/apps/edit_ml_model_version.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ml/model_registry/apps/edit_ml_model.vue', () => {
  let wrapper;

  const mountComponent = (canWriteModelRegistry) => {
    wrapper = shallowMountExtended(EditMlModelVersion, {
      propsData: {
        projectPath: 'project/path',
        canWriteModelRegistry,
        markdownPreviewPath: 'markdown/preview/path',
        modelVersionPath: 'model/version/path',
        modelGid: 'gid://gitlab/Ml::Model/1',
        modelVersionVersion: '1.0.0',
        modelVersionDescription: 'No desc',
      },
    });
  };

  const findModelVersionEdit = () => wrapper.findComponent(ModelVersionEdit);

  it('when user has no permission does not render the model edit component', () => {
    mountComponent(false);

    expect(findModelVersionEdit().exists()).toBe(false);
  });

  it('when user has permission renders the model edit component', () => {
    mountComponent(true);

    expect(findModelVersionEdit().props()).toEqual({
      projectPath: 'project/path',
      disableAttachments: false,
      modelWithVersion: {
        id: 'gid://gitlab/Ml::Model/1',
        version: {
          version: '1.0.0',
          description: 'No desc',
        },
      },
      modelVersionPath: 'model/version/path',
      markdownPreviewPath: 'markdown/preview/path',
    });
  });
});
