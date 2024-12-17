import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import MlflowUsageModal from '~/ml/experiment_tracking/routes/experiments/index/components/mlflow_usage_modal.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/experiment_tracking/routes/experiments/index/constants';

let wrapper;
const createWrapper = () => {
  wrapper = shallowMount(MlflowUsageModal, {
    provide: { mlflowTrackingUrl: 'path/to/mlflow' },
  });
};

const findModal = () => wrapper.findComponent(GlModal);

describe('ml/experiment_tracking/routes/experiments/index/components/mlflow_usage_modal.vue', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('renders the modal with correct props', () => {
    expect(findModal().props()).toMatchObject({
      title: 'Using the MLflow client',
      modalId: MLFLOW_USAGE_MODAL_ID,
    });
  });

  it('renders the text', () => {
    const text = findModal().text();
    const expectedLines = [
      'Creating experiments using the MLflow client:',
      // 'Creating an experiment',
      'import os',
      'from mlflow import MlflowClient',
      'os.environ["MLFLOW_TRACKING_URI"] = "path/to/mlflow"',
      'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
      'client = MlflowClient()',
      "client.create_experiment(name=\"<your_experiment_name>\", tags={'key': 'value'})",
    ];
    expectedLines.forEach((line) => expect(text).toContain(line));
  });
});
