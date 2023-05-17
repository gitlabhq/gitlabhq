import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TakeOwnershipModalLegacy from '~/ci/pipeline_schedules/components/take_ownership_modal_legacy.vue';

describe('Take ownership modal', () => {
  let wrapper;
  const url = `/root/job-log-tester/-/pipeline_schedules/3/take_ownership`;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TakeOwnershipModalLegacy, {
      propsData: {
        ownershipUrl: url,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    createComponent();
  });

  it('has a primary action set to a url and a post data-method', () => {
    const actionPrimary = findModal().props('actionPrimary');

    expect(actionPrimary.attributes).toEqual(
      expect.objectContaining({
        category: 'primary',
        variant: 'confirm',
        href: url,
        'data-method': 'post',
      }),
    );
  });

  it('shows a take ownership message', () => {
    expect(findModal().text()).toBe(
      'Only the owner of a pipeline schedule can make changes to it. Do you want to take ownership of this schedule?',
    );
  });
});
