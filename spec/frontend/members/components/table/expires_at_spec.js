import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ExpiresAt from '~/members/components/table/expires_at.vue';

describe('ExpiresAt', () => {
  // March 15th, 2020
  useFakeDate(2020, 2, 15);

  let wrapper;

  const createComponent = (propsData) => {
    wrapper = mount(ExpiresAt, {
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(within(wrapper.element).getByText(text, options));

  const getTooltipDirective = (elementWrapper) => getBinding(elementWrapper.element, 'gl-tooltip');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when no expiration date is set', () => {
    it('displays "No expiration set"', () => {
      createComponent({ date: null });

      expect(getByText('No expiration set').exists()).toBe(true);
    });
  });

  describe('when expiration date is in the past', () => {
    let expiredText;

    beforeEach(() => {
      createComponent({ date: '2019-03-15T00:00:00.000' });

      expiredText = getByText('Expired');
    });

    it('displays "Expired"', () => {
      expect(expiredText.exists()).toBe(true);
      expect(expiredText.classes()).toContain('gl-text-red-500');
    });

    it('displays tooltip with formatted date', () => {
      const tooltipDirective = getTooltipDirective(expiredText);

      expect(tooltipDirective).not.toBeUndefined();
      expect(expiredText.attributes('title')).toBe('Mar 15, 2019 12:00am UTC');
    });
  });

  describe('when expiration date is in the future', () => {
    it.each`
      date                         | expected                   | warningColor
      ${'2020-03-23T00:00:00.000'} | ${'in 8 days'}             | ${false}
      ${'2020-03-20T00:00:00.000'} | ${'in 5 days'}             | ${true}
      ${'2020-03-16T00:00:00.000'} | ${'in 1 day'}              | ${true}
      ${'2020-03-15T05:00:00.000'} | ${'in about 5 hours'}      | ${true}
      ${'2020-03-15T01:00:00.000'} | ${'in about 1 hour'}       | ${true}
      ${'2020-03-15T00:30:00.000'} | ${'in 30 minutes'}         | ${true}
      ${'2020-03-15T00:01:15.000'} | ${'in 1 minute'}           | ${true}
      ${'2020-03-15T00:00:15.000'} | ${'in less than a minute'} | ${true}
    `('displays "$expected"', ({ date, expected, warningColor }) => {
      createComponent({ date });

      const expiredText = getByText(expected);

      expect(expiredText.exists()).toBe(true);

      if (warningColor) {
        expect(expiredText.classes()).toContain('gl-text-orange-500');
      } else {
        expect(expiredText.classes()).not.toContain('gl-text-orange-500');
      }
    });
  });
});
