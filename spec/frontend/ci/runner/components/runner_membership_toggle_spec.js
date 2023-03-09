import { GlToggle } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import RunnerMembershipToggle from '~/ci/runner/components/runner_membership_toggle.vue';
import {
  I18N_SHOW_ONLY_INHERITED,
  MEMBERSHIP_DESCENDANTS,
  MEMBERSHIP_ALL_AVAILABLE,
} from '~/ci/runner/constants';

describe('RunnerMembershipToggle', () => {
  let wrapper;

  const findToggle = () => wrapper.findComponent(GlToggle);

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerMembershipToggle, {
      propsData: props,
    });
  };

  it('Displays text', () => {
    createComponent({ mountFn: mount });

    expect(wrapper.text()).toBe(I18N_SHOW_ONLY_INHERITED);
  });

  it.each`
    membershipValue             | toggleValue
    ${MEMBERSHIP_DESCENDANTS}   | ${true}
    ${MEMBERSHIP_ALL_AVAILABLE} | ${false}
  `(
    'Displays a membership of $membershipValue as enabled=$toggleValue',
    ({ membershipValue, toggleValue }) => {
      createComponent({ props: { value: membershipValue } });

      expect(findToggle().props('value')).toBe(toggleValue);
    },
  );

  it.each`
    changeEvt | membershipValue
    ${true}   | ${MEMBERSHIP_DESCENDANTS}
    ${false}  | ${MEMBERSHIP_ALL_AVAILABLE}
  `(
    'Emits $changeEvt when value is changed to $membershipValue',
    ({ changeEvt, membershipValue }) => {
      createComponent();
      findToggle().vm.$emit('change', changeEvt);

      expect(wrapper.emitted('input')).toStrictEqual([[membershipValue]]);
    },
  );
});
