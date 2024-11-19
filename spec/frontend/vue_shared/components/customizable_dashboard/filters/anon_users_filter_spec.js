import { GlToggle, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import AnonUsersFilter from '~/vue_shared/components/customizable_dashboard/filters/anon_users_filter.vue';

describe('AnonUsersFilter', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(AnonUsersFilter, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...props,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findHelpIcon = () => wrapper.findComponent(GlIcon);

  describe('default behaviour', () => {
    it('renders the toggle', () => {
      createWrapper({ value: false });

      expect(findToggle().props()).toMatchObject({
        label: 'Exclude anonymous users',
        labelPosition: 'left',
      });
    });

    it.each([true, false])('sets the toggle value when the value prop is %s', (value) => {
      createWrapper({ value });

      expect(findToggle().props('value')).toBe(value);
    });

    it('bubbles up the "change" event', async () => {
      createWrapper({ value: false });

      await findToggle().vm.$emit('change', true);

      expect(wrapper.emitted('change')).toStrictEqual([[true]]);
    });

    it('should show an icon with a tooltip explaining the filter', () => {
      createWrapper({ value: false });

      const helpIcon = findHelpIcon();
      const tooltip = getBinding(helpIcon.element, 'gl-tooltip');

      expect(helpIcon.props('name')).toBe('information-o');
      expect(helpIcon.attributes('title')).toBe(
        'View metrics only for users who have consented to activity tracking.',
      );
      expect(tooltip).toBeDefined();
    });
  });
});
