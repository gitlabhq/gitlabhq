import { GlButton } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CancelJobs from '~/ci/admin/jobs_table/components/cancel_jobs.vue';
import CancelJobsModal from '~/ci/admin/jobs_table/components/cancel_jobs_modal.vue';
import { CANCEL_JOBS_MODAL_ID, CANCEL_BUTTON_TOOLTIP } from '~/ci/admin/jobs_table/constants';

describe('CancelJobs component', () => {
  let wrapper;

  const findCancelJobs = () => wrapper.findComponent(CancelJobs);
  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(CancelJobsModal);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CancelJobs, {
      directives: {
        GlModal: createMockDirective('gl-modal'),
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        url: `${TEST_HOST}/cancel_jobs_modal.vue/cancelAll`,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('has correct inputs', () => {
    expect(findCancelJobs().props().url).toBe(`${TEST_HOST}/cancel_jobs_modal.vue/cancelAll`);
  });

  it('has correct button variant', () => {
    expect(findButton().props().variant).toBe('danger');
  });

  it('checks that button and modal are connected', () => {
    const buttonModalDirective = getBinding(findButton().element, 'gl-modal');
    const modalId = findModal().props('modalId');

    expect(buttonModalDirective.value).toBe(CANCEL_JOBS_MODAL_ID);
    expect(modalId).toBe(CANCEL_JOBS_MODAL_ID);
  });

  it('checks that tooltip is displayed', () => {
    const buttonTooltipDirective = getBinding(findButton().element, 'gl-tooltip');

    expect(buttonTooltipDirective.value).toBe(CANCEL_BUTTON_TOOLTIP);
  });
});
