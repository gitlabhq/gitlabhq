import { mountExtended } from 'helpers/vue_test_utils_helper';
import VerificationRecoverAccount from '~/authentication/sessions/components/verification_recover_account.vue';

describe('VerificationRecoverAccount', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(VerificationRecoverAccount);
  };

  const findRecoveryButton = () => wrapper.findByTestId('recovery-button');

  beforeEach(() => {
    createComponent();
  });

  it('renders the recover-account prompt and link', () => {
    expect(wrapper.text()).toContain('Having trouble signing in?');
    expect(findRecoveryButton().text()).toBe('Recover your account');
  });

  it('emits recover when the link is clicked', () => {
    findRecoveryButton().vm.$emit('click');

    expect(wrapper.emitted('recover')).toHaveLength(1);
  });
});
