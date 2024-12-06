import ModelVersionCreate from '~/ml/model_registry/components/model_version_create.vue';
import NewMlModelVersion from '~/ml/model_registry/apps/new_ml_model_version.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ml/model_registry/apps/new_ml_model_version.vue', () => {
  let wrapper;

  const mountComponent = ({ canWriteModelRegistry = false } = {}) => {
    wrapper = shallowMountExtended(NewMlModelVersion, {
      propsData: {
        modelPath: 'project/model/path',
        projectPath: 'project/path',
        canWriteModelRegistry,
        maxAllowedFileSize: 1000,
        markdownPreviewPath: 'markdown/preview/path',
        latestVersion: '1.0.1',
        modelGid: 'gid://gitlab/Ml::Model/1',
      },
    });
  };

  const findModelVersion = () => wrapper.findComponent(ModelVersionCreate);

  it('when user has no permission renders the model create component', () => {
    mountComponent({ canWriteModelRegistry: false });

    expect(findModelVersion().exists()).toBe(false);
  });

  it('when user has permission renders the model create component', () => {
    mountComponent({ canWriteModelRegistry: true });

    expect(findModelVersion().exists()).toBe(true);
  });
});
