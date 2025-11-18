import { GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateWithTooltip from '~/vue_shared/access_tokens/components/personal_access_tokens/date_with_tooltip.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { toISODateFormat } from '~/lib/utils/datetime/date_format_utility';
import { nDaysAfter } from '~/lib/utils/datetime/date_calculation_utility';

describe('Date with tooltip component', () => {
  let wrapper;

  const createWrapper = ({ timestamp = '2020-10-20T12:34:56', icon, token, slotContent } = {}) => {
    wrapper = shallowMountExtended(DateWithTooltip, {
      propsData: { timestamp, icon, token },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      scopedSlots: slotContent ? { default: slotContent } : null,
    });
  };

  const findTooltip = () => getBinding(wrapper.find('span').element, 'gl-tooltip');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const getDate = (daysAfter = 0) => toISODateFormat(nDaysAfter(new Date(), daysAfter));

  describe('when there is a timestamp', () => {
    beforeEach(() => createWrapper());

    it('shows date', () => {
      expect(wrapper.text()).toBe('Oct 20, 2020');
    });

    it('has tooltip', () => {
      expect(findTooltip()).toEqual({
        modifiers: { d0: true },
        value: 'October 20, 2020 at 12:34:56 PM GMT',
      });
    });
  });

  describe('when there is no timestamp', () => {
    beforeEach(() => createWrapper({ timestamp: null }));

    it('shows "Never"', () => {
      expect(wrapper.text()).toBe('Never');
    });

    it('does not have tooltip', () => {
      expect(findTooltip()).toEqual({
        modifiers: { d0: true },
        value: null,
      });
    });
  });

  describe('when there is slot content', () => {
    beforeEach(() => createWrapper({ slotContent: '<span>Expires: {{ props.date }}</span>' }));

    it('shows date', () => {
      expect(wrapper.text()).toBe('Expires: Oct 20, 2020');
    });

    it('has tooltip', () => {
      expect(findTooltip()).toEqual({
        modifiers: { d0: true },
        value: 'October 20, 2020 at 12:34:56 PM GMT',
      });
    });
  });

  describe('icon', () => {
    it('does not show icon when there is no icon prop', () => {
      createWrapper();

      expect(findIcon().exists()).toBe(false);
    });

    it('shows icon when icon prop is provided', () => {
      createWrapper({ icon: 'expire' });

      expect(findIcon().props('name')).toBe('expire');
    });
  });

  describe('badges', () => {
    it('does not show badge when there is no token prop', () => {
      createWrapper();

      expect(findBadge().exists()).toBe(false);
    });

    it.each`
      text               | active   | revoked  | expiresAt     | icon          | variant
      ${'Revoked'}       | ${false} | ${true}  | ${getDate()}  | ${'remove'}   | ${'danger'}
      ${'Expired'}       | ${false} | ${false} | ${getDate()}  | ${'time-out'} | ${'neutral'}
      ${'Expiring soon'} | ${true}  | ${false} | ${getDate(5)} | ${'expire'}   | ${'warning'}
    `(
      'shows $text badge when token is $text',
      ({ text, active, revoked, expiresAt, icon, variant }) => {
        createWrapper({ token: { active, revoked, expiresAt } });

        expect(findBadge().props()).toMatchObject({ icon, variant });
        expect(findBadge().text()).toBe(text);
      },
    );

    it('does not show badge if token is active, not revoked, and not expiring soon', () => {
      createWrapper({ token: { active: true, revoked: false, expiresAt: getDate(20) } });

      expect(findBadge().exists()).toBe(false);
    });

    it('shows tooltip for expiring soon badge', () => {
      createWrapper({ token: { active: true, expiresAt: getDate(5) } });

      expect(getBinding(findBadge().element, 'gl-tooltip')).toEqual({
        modifiers: { d0: true },
        value: 'Token expires in less than two weeks.',
      });
    });
  });
});
