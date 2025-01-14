import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import JobActionModal from '~/ci/common/private/job_action_modal.vue';

describe('JobActionModal', () => {
  let wrapper;

  const defaultProps = {
    customMessage: 'This is a custom message.',
    jobName: 'test_job',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(JobActionModal, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    createComponent();
  });

  it('shows modal', () => {
    expect(findModal().props()).toMatchObject({
      actionCancel: { text: 'Cancel' },
      actionPrimary: { text: 'Yes, run test_job' },
      modalId: 'job-action-modal',
      title: 'Are you sure you want to run test_job?',
    });
  });

  it('displays the custom message', () => {
    expect(findModal().text()).toContain(defaultProps.customMessage);
  });

  it('emits change event when modal visibility changes', async () => {
    await findModal().vm.$emit('change', true);
    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  it('passes visible prop to gl-modal', () => {
    createComponent({
      props: {
        visible: true,
      },
    });

    expect(findModal().props('visible')).toBe(true);
  });
});
