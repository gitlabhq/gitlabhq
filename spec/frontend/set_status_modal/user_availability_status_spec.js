import { shallowMount } from '@vue/test-utils';
import UserAvailabilityStatus from '~/set_status_modal/components/user_availability_status.vue';
import { AVAILABILITY_STATUS } from '~/set_status_modal/utils';

describe('UserAvailabilityStatus', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(UserAvailabilityStatus, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with availability status', () => {
    it(`set to ${AVAILABILITY_STATUS.BUSY}`, () => {
      wrapper = createComponent({ availability: AVAILABILITY_STATUS.BUSY });
      expect(wrapper.text()).toContain('(Busy)');
    });

    it(`set to ${AVAILABILITY_STATUS.NOT_SET}`, () => {
      wrapper = createComponent({ availability: AVAILABILITY_STATUS.NOT_SET });
      expect(wrapper.html()).toBe('');
    });
  });
});
