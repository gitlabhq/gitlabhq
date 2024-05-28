import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/ml/model_registry/components/model_list_empty_state.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(EmptyState, {
    provide: { mlflowTrackingUrl: 'path/to/mlflow', createModelPath: '/path/to/create' },
  });
};

const findEmptyState = () => wrapper.findComponent(GlEmptyState);
const findCopyButton = () => wrapper.findComponent(ClipboardButton);
const findCreateButton = () => wrapper.findComponent(GlButton);
const findDocsButton = () => wrapper.findAllComponents(GlButton).at(1);

const mlflowCmd = [
  'import os',
  'from mlflow import MlflowClient',
  '',
  'os.environ["MLFLOW_TRACKING_URI"] = "path/to/mlflow"',
  'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
  '',
  '# Create a model',
  'client = MlflowClient()',
  "model_name = '<your_model_name>'",
  "description = 'Model description'",
  'model = client.create_registered_model(model_name, description=description)',
  '',
  '# Create a version',
  'tags = { "gitlab.version": version }',
  'model_version = client.create_model_version(model_name, version, tags=tags)',
  '',
  '# Log artifacts',
  'client.log_artifact(run_id, \'<local/path/to/file.txt>\', artifact_path="")',
].join('\n');

describe('ml/model_registry/components/model_list_empty_state.vue', () => {
  beforeEach(() => {
    createWrapper();
  });

  describe('when entity type is model', () => {
    it('shows the correct empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'No models registered',
        svgPath: 'file-mock',
      });

      expect(findEmptyState().text()).toContain(
        'Import your machine learning using GitLab directly or using the MLflow client:',
      );
      expect(findEmptyState().text()).toContain(mlflowCmd);
    });

    it('creates the copy text button', () => {
      expect(findCopyButton().props('text')).toBe(mlflowCmd);
    });

    it('creates button to open model creation', () => {
      expect(findCreateButton().text()).toBe('Create model');
    });

    it('clicking creates triggers open-create-model', async () => {
      await findCreateButton().vm.$emit('click');

      expect(wrapper.emitted('open-create-model')).toHaveLength(1);
    });

    it('creates button to docs', () => {
      expect(findDocsButton().text()).toBe('MLflow compatibility');
      expect(findDocsButton().attributes('href')).toBe(
        '/help/user/project/ml/model_registry/index#creating-machine-learning-models-and-model-versions',
      );
    });
  });
});
