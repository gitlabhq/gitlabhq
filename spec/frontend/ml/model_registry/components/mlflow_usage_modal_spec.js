import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import MlflowUsageModal from '~/ml/model_registry/components/mlflow_usage_modal.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/model_registry/constants';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(MlflowUsageModal, {
    provide: { mlflowTrackingUrl: 'path/to/mlflow' },
  });
};

const findModal = () => wrapper.findComponent(GlModal);

describe('ml/model_registry/components/mlflow_usage_modal.vue', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('renders the modal with correct props', () => {
    expect(findModal().props()).toMatchObject({
      title: 'Using the MLflow client',
      modalId: MLFLOW_USAGE_MODAL_ID,
      actionPrimary: {
        text: 'MLflow compatibility documentation',
        attributes: {
          variant: 'confirm',
        },
      },
    });
  });

  it('renders the text', () => {
    const text = findModal().text();
    const expectedLines = [
      'Creating models, model versions and runs is also possible using the MLflow client',
      'Setting up the client',
      'import os',
      'from mlflow import MlflowClient',
      'os.environ["MLFLOW_TRACKING_URI"] = "path/to/mlflow"',
      'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
      'Creating a model',
      'client = MlflowClient()',
      "model_name = '<your_model_name>'",
      "description = 'Model description'",
      'model = client.create_registered_model(model_name, description=description)',
      'Creating a model version',
      'tags = { "gitlab.version": version }',
      'model_version = client.create_model_version(model_name, version, tags=tags)',
      'Logging artifacts',
      'client.log_artifact(run_id, \'<local/path/to/file.txt>\', artifact_path="")',
    ];

    expectedLines.forEach((line) => expect(text).toContain(line));
  });
});
