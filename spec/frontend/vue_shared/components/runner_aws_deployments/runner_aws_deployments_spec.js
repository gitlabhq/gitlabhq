import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RunnerAwsDeployments from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments.vue';
import RunnerAwsDeploymentsModal from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments_modal.vue';

describe('RunnerAwsDeployments component', () => {
  let wrapper;

  const findModalButton = () => wrapper.findByTestId('show-modal-button');
  const findModal = () => wrapper.findComponent(RunnerAwsDeploymentsModal);

  const createComponent = () => {
    wrapper = extendedWrapper(shallowMount(RunnerAwsDeployments));
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should show the "Deploy GitLab Runner in AWS" button', () => {
    expect(findModalButton().exists()).toBe(true);
    expect(findModalButton().text()).toBe('Deploy GitLab Runner in AWS');
  });

  it('should not render the modal once mounted', () => {
    expect(findModal().exists()).toBe(false);
  });

  it('should render the modal once clicked', async () => {
    findModalButton().vm.$emit('click');

    await nextTick();

    expect(findModal().exists()).toBe(true);
  });
});
