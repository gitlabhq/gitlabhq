import { GlFormGroup, GlSprintf, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PushProtections, {
  i18n,
} from '~/projects/settings/branch_rules/components/edit/protections/push_protections.vue';
import { membersAllowedToPush, allowForcePush } from '../../../mock_data';

describe('Push Protections', () => {
  let wrapper;
  const propsData = {
    membersAllowedToPush,
    allowForcePush,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(PushProtections, {
      propsData,
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findAllowForcePushCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findHelpText = () => wrapper.findComponent(GlSprintf);

  beforeEach(() => createComponent());

  it('renders a form group with the correct label', () => {
    expect(findFormGroup().attributes('label')).toBe(i18n.allowedToPush);
  });

  describe('Allow force push checkbox', () => {
    it('renders a checkbox with the correct props', () => {
      expect(findAllowForcePushCheckbox().vm.$attrs.checked).toBe(propsData.allowForcePush);
    });

    it('renders help text', () => {
      expect(findHelpText().attributes('message')).toBe(i18n.forcePushTitle);
    });

    it('emits a change-allow-force-push event when changed', () => {
      findAllowForcePushCheckbox().vm.$emit('change', false);

      expect(wrapper.emitted('change-allow-force-push')[0]).toEqual([false]);
    });
  });
});
