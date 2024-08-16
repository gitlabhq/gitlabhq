import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoolPresenter from '~/glql/components/presenters/bool.vue';

describe('BoolPresenter', () => {
  it.each`
    boolValue | presentedAs
    ${true}   | ${'Yes'}
    ${false}  | ${'No'}
  `(
    'for boolean value $boolValue, it presents it as "$presentedAs"',
    ({ boolValue, presentedAs }) => {
      const wrapper = shallowMountExtended(BoolPresenter, { propsData: { data: boolValue } });

      expect(wrapper.text()).toBe(presentedAs);
    },
  );
});
