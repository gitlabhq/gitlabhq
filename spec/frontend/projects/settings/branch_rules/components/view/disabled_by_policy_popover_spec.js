import { GlPopover, GlSprintf } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DisabledByPolicyPopover from '~/projects/settings/branch_rules/components/view/disabled_by_policy_popover.vue';

describe('DisabledByPolicyPopover', () => {
  let wrapper;

  const securityPoliciesPath = '/test-group/test-project/-/security/policies';

  const createComponent = () => {
    wrapper = shallowMountExtended(DisabledByPolicyPopover, {
      provide: { securityPoliciesPath },
      stubs: { GlSprintf },
    });
  };

  const findTriggerButton = () => wrapper.find('button');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findSecurityPoliciesPathLink = () => wrapper.findByTestId('security-policies-path-link');
  const findLearnMoreLink = () => wrapper.findByTestId('learn-more-link');

  beforeEach(() => {
    createComponent();
  });

  it('renders the popover with correct props', () => {
    expect(findPopover().props('triggers')).toBe('hover focus');
    expect(findPopover().props('title')).toBe('Setting blocked by security policy');
    expect(findPopover().props('target')).toMatch(/^security-policy-info-/);
  });

  it('renders the help link with correct href', () => {
    expect(findSecurityPoliciesPathLink().attributes('href')).toBe(
      '/test-group/test-project/-/security/policies',
    );
  });

  it('renders the learn more link with correct href', () => {
    expect(findLearnMoreLink().attributes('href')).toBe(
      '/help/user/application_security/policies/merge_request_approval_policies#approval_settings',
    );
  });

  it('shows the default description message', () => {
    expect(trimText(findPopover().text())).toBe(
      'This setting is blocked by a security policy. To make changes, go to the security policies. Learn more.',
    );
  });

  it('renders the trigger button with correct attributes', () => {
    expect(findTriggerButton().attributes('aria-label')).toBe(
      'This setting is blocked by a security policy. To make changes, go to the security policies. Learn more.',
    );
  });
});
