import GuestOverageConfirmation from '~/members/components/table/guest_overage_confirmation.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('Guest overage confirmation', () => {
  it('emits confirm event when confirmOverage is called', () => {
    const wrapper = mountExtended(GuestOverageConfirmation);
    wrapper.vm.confirmOverage();

    expect(wrapper.emitted('confirm')).toHaveLength(1);
  });
});
