import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { s__ } from '~/locale';
import RunnerAwsDeploymentsModal from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments_modal.vue';
import RunnerAwsInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_aws_instructions.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockModalId = 'runner-aws-deployments-modal';

describe('RunnerAwsDeploymentsModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findRunnerAwsInstructions = () => wrapper.findComponent(RunnerAwsInstructions);

  const createComponent = (options) => {
    wrapper = shallowMount(RunnerAwsDeploymentsModal, {
      propsData: {
        modalId: mockModalId,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders modal', () => {
    expect(findModal().props()).toMatchObject({
      size: 'sm',
      modalId: mockModalId,
      title: s__('Runners|Deploy GitLab Runner in AWS'),
    });
    expect(findModal().attributes()).toMatchObject({
      'hide-footer': '',
    });
  });

  it('renders modal contents', () => {
    expect(findRunnerAwsInstructions().exists()).toBe(true);
  });

  it('when contents trigger closing, modal closes', () => {
    const mockClose = jest.fn();

    createComponent({
      stubs: {
        GlModal: {
          template: '<div><slot/></div>',
          methods: {
            close: mockClose,
          },
        },
      },
    });

    expect(mockClose).toHaveBeenCalledTimes(0);

    findRunnerAwsInstructions().vm.$emit('close');

    expect(mockClose).toHaveBeenCalledTimes(1);
  });
});
