import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import MlflowUsageModal from '~/ml/experiment_tracking/routes/experiments/index/components/mlflow_usage_modal.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/experiment_tracking/routes/experiments/index/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

let wrapper;

const command = `import os
from mlflow import MlflowClient

os.environ["MLFLOW_TRACKING_URI"] = "path/to/mlflow"
os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>

client = MlflowClient()

client.create_experiment(name="<your_experiment_name>", tags={'key': 'value'})`;

const createWrapper = () => {
  wrapper = shallowMount(MlflowUsageModal, {
    provide: { mlflowTrackingUrl: 'path/to/mlflow' },
  });
};

const findModal = () => wrapper.findComponent(GlModal);
const findCmd = () => findModal().find('code');
const findCopyButton = () => findModal().findComponent(ClipboardButton);

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

  it('renders the intro text', () => {
    expect(wrapper.text()).toMatch('Creating experiments using the MLflow client:');
  });

  it('renders the cmd', () => {
    expect(findCmd().text()).toBe(command);
  });

  describe('copy button', () => {
    it('renders the button correctly', () => {
      expect(findCopyButton().props('text')).toBe(command);
      expect(findCopyButton().props('title')).toBe('Copy to clipboard');
    });

    it('copies the code to the clipboard on click', async () => {
      const copySpy = jest.spyOn(navigator.clipboard, 'writeText');

      await findCopyButton().vm.$emit('click');

      expect(copySpy).toHaveBeenCalledWith(command);
    });
  });
});
