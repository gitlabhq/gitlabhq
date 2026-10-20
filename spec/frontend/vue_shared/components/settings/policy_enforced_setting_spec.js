import { GlLink, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyEnforcedSetting from '~/vue_shared/components/settings/policy_enforced_setting.vue';

describe('PolicyEnforcedSetting', () => {
  let wrapper;

  const enforcePolicy = {
    name: 'Lock request access',
    webPath: '/groups/acme/-/security/policy_store/7',
  };
  const warnPolicy = {
    name: 'Request access review',
    webPath: '/groups/acme/-/security/policy_store/9',
  };
  const auditPolicy = {
    name: 'Request access audit',
    webPath: '/groups/acme/-/security/policy_store/11',
  };

  const enforceRow = { mode: 'enforce', policy: enforcePolicy, message: null };
  const warnRow = {
    mode: 'warn',
    policy: warnPolicy,
    message: 'Disable request access before the audit.',
  };
  const auditRow = { mode: 'audit', policy: auditPolicy, message: null };

  const createComponent = ({ enforcements = [], policyStoreSettingEnforcement = true } = {}) => {
    wrapper = mountExtended(PolicyEnforcedSetting, {
      propsData: { enforcements },
      provide: { glFeatures: { policyStoreSettingEnforcement } },
      scopedSlots: {
        default:
          '<input data-testid="control" type="checkbox" :disabled="props.disabled" :aria-describedby="props.describedBy" />',
      },
    });
  };

  const findControl = () => wrapper.findByTestId('control');
  const findLock = () => wrapper.findByTestId('policy-enforced-setting-lock');
  const findWarning = () => wrapper.findByTestId('policy-enforced-setting-warning');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPolicyLink = () => wrapper.findByTestId('policy-enforced-setting-link');
  const findDescription = () => wrapper.find(`#${findControl().attributes('aria-describedby')}`);

  const expectUnchanged = () => {
    expect(findControl().attributes('disabled')).toBeUndefined();
    expect(findControl().attributes('aria-describedby')).toBeUndefined();
    expect(findLock().exists()).toBe(false);
    expect(findWarning().exists()).toBe(false);
  };

  describe('when the feature flag is disabled', () => {
    it.each`
      description  | enforcements
      ${'enforce'} | ${[enforceRow]}
      ${'warn'}    | ${[warnRow]}
      ${'audit'}   | ${[auditRow]}
      ${'no rows'} | ${[]}
    `('renders the bare slot for $description', ({ enforcements }) => {
      createComponent({ enforcements, policyStoreSettingEnforcement: false });

      expectUnchanged();
    });
  });

  describe('without a governing policy', () => {
    it.each`
      description         | enforcements
      ${'an empty list'}  | ${[]}
      ${'null'}           | ${null}
      ${'an unknown row'} | ${[{ mode: 'block', policy: enforcePolicy }]}
    `('renders the bare slot for $description', ({ enforcements }) => {
      createComponent({ enforcements });

      expectUnchanged();
    });
  });

  describe('in audit mode', () => {
    it('renders the bare slot', () => {
      createComponent({ enforcements: [auditRow] });

      expectUnchanged();
    });
  });

  describe('in enforce mode', () => {
    beforeEach(() => {
      createComponent({ enforcements: [enforceRow] });
    });

    it('disables the slotted control', () => {
      expect(findControl().attributes('disabled')).toBeDefined();
    });

    it('renders a focusable lock button that names the policy', () => {
      expect(findLock().element.tagName).toBe('BUTTON');
      expect(findLock().attributes('aria-label')).toBe(
        'This setting is managed by the policy Lock request access and cannot be changed here.',
      );
    });

    it('explains the lock in a popover linking to the policy', () => {
      expect(findPopover().props('title')).toBe('Setting managed by policy');
      expect(findPopover().props('target')).toBe(findLock().attributes('id'));
      expect(findPopover().text()).toContain(
        'This setting is managed by the policy Lock request access and cannot be changed here.',
      );
      expect(findPolicyLink().attributes('href')).toBe(enforcePolicy.webPath);
    });

    it('describes the control with the reason for assistive technology', () => {
      expect(findDescription().text()).toBe(findLock().attributes('aria-label'));
      expect(findDescription().attributes('hidden')).toBeDefined();
    });

    it('does not render a warning notice', () => {
      expect(findWarning().exists()).toBe(false);
    });

    it('still disables the control when an unknown row is listed first', () => {
      createComponent({ enforcements: [{ mode: 'block', policy: warnPolicy }, enforceRow] });

      expect(findControl().attributes('disabled')).toBeDefined();
      expect(findPolicyLink().text()).toBe('Lock request access');
    });
  });

  describe('in warn mode', () => {
    beforeEach(() => {
      createComponent({ enforcements: [warnRow] });
    });

    it('keeps the slotted control enabled', () => {
      expect(findControl().attributes('disabled')).toBeUndefined();
      expect(findLock().exists()).toBe(false);
    });

    it('renders the notice with the policy link and the author message', () => {
      expect(findWarning().text()).toContain(
        'This setting does not comply with the policy Request access review.',
      );
      expect(findWarning().text()).toContain('Disable request access before the audit.');
      expect(findWarning().findComponent(GlLink).attributes('href')).toBe(warnPolicy.webPath);
    });

    it('describes the control with the notice', () => {
      expect(findDescription().element).toBe(findWarning().element);
    });

    it('omits the author message when there is none', () => {
      createComponent({ enforcements: [{ ...warnRow, message: null }] });

      expect(findWarning().text()).toContain(
        'This setting does not comply with the policy Request access review.',
      );
      expect(findWarning().text()).not.toContain('Disable request access before the audit.');
    });

    it('shows only the strongest warn policy when several warn', () => {
      createComponent({
        enforcements: [warnRow, { ...warnRow, policy: auditPolicy, message: 'Second notice.' }],
      });

      expect(wrapper.findAllByTestId('policy-enforced-setting-warning')).toHaveLength(1);
      expect(findWarning().text()).toContain('Request access review');
      expect(findWarning().text()).not.toContain('Second notice.');
    });
  });

  describe('with several governing policies', () => {
    it('renders the strongest mode and lists the other visible policies once', () => {
      createComponent({
        enforcements: [auditRow, warnRow, { ...warnRow, message: null }, enforceRow],
      });

      expect(findControl().attributes('disabled')).toBeDefined();
      expect(findPolicyLink().text()).toBe('Lock request access');
      expect(findPopover().text()).toContain('Also governed by Request access review.');
      expect(findPopover().text()).not.toContain('Request access audit');
    });

    it('omits the list when no other policy is visible', () => {
      createComponent({ enforcements: [enforceRow, auditRow] });

      expect(findPopover().text()).not.toContain('Also governed by');
    });
  });
});
