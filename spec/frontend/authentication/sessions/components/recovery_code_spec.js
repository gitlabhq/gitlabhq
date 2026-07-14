import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RecoveryCode from '~/authentication/sessions/components/recovery_code.vue';
import { newAdminSessionPath } from '~/lib/utils/path_helpers/admin';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('RecoveryCode', () => {
  let wrapper;

  const defaultProps = {
    path: '/users/sign_in',
    rememberMe: '1',
    rememberMeEnabled: true,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(RecoveryCode, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findForm = () => wrapper.find('form');
  const findField = () => wrapper.findByTestId('recovery-code-field');
  const findVerifyButton = () => wrapper.findByTestId('verify-recovery-code-button');
  const findCsrfInput = () => wrapper.find('input[name="authenticity_token"]');
  const findRememberMeInput = () => wrapper.find('input[name="user[remember_me]"]');
  const findMethodInput = () => wrapper.find('input[name="two_factor_method"]');
  const findLinkByHref = (fragment) =>
    wrapper
      .findAllComponents(GlLink)
      .wrappers.find((link) => link.attributes('href')?.includes(fragment));
  const findRecoveryCodesLink = () => findLinkByHref('#recovery-codes');
  const findSshLink = () => findLinkByHref('#regenerate-recovery-codes-with-ssh');
  const findBackButton = () => wrapper.findByTestId('back-to-sign-in-button');

  beforeEach(() => {
    createComponent();
  });

  it('renders the heading and description', () => {
    expect(wrapper.text()).toContain('Enter account recovery code');
    expect(wrapper.text()).toContain(
      'Enter one of the recovery codes generated when you added two-factor authentication to your account.',
    );
  });

  it('renders the recovery codes help link opening in a new tab', () => {
    expect(findRecoveryCodesLink().attributes('href')).toContain('#recovery-codes');
    expect(findRecoveryCodesLink().attributes('target')).toBe('_blank');
  });

  it('renders the SSH help link opening in a new tab', () => {
    expect(findSshLink().attributes('href')).toContain('#regenerate-recovery-codes-with-ssh');
    expect(findSshLink().attributes('target')).toBe('_blank');
  });

  it('renders the code field with autocomplete off and the otp name', () => {
    expect(findField().attributes('autocomplete')).toBe('off');
    expect(findField().attributes('name')).toBe('user[otp_attempt]');
  });

  it('does not give the recovery field an otp-named id (avoids password-manager OTP autofill)', () => {
    expect(findField().attributes('id')).not.toBe('user_otp_attempt');
  });

  it('renders the verify button with confirm variant', () => {
    expect(findVerifyButton().props('variant')).toBe('confirm');
  });

  it('renders the CSRF input', () => {
    expect(findCsrfInput().attributes('value')).toBe('mock-csrf-token');
  });

  it('submits recovery as the two_factor_method hint', () => {
    expect(findMethodInput().attributes('value')).toBe('recovery');
  });

  it('renders the remember-me input when rememberMeEnabled is true', () => {
    expect(findRememberMeInput().exists()).toBe(true);
  });

  it('does not render the remember-me input when rememberMeEnabled is false', () => {
    createComponent({ rememberMeEnabled: false });

    expect(findRememberMeInput().exists()).toBe(false);
  });

  it('renders the form pointing at path with post method', () => {
    expect(findForm().attributes('action')).toBe(defaultProps.path);
    expect(findForm().attributes('method')).toBe('post');
  });

  it('renders "Back to sign-in" as a link to the sign-in page', () => {
    expect(findBackButton().attributes('href')).toBe(newUserSessionPath());
  });

  it('links "Back to sign-in" to the admin session page in admin mode', () => {
    createComponent({ adminMode: true });

    expect(findBackButton().attributes('href')).toBe(newAdminSessionPath());
  });
});
