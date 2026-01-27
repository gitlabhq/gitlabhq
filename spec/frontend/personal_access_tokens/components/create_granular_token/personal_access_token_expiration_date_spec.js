import { GlFormGroup, GlDatepicker } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenExpirationDate from '~/personal_access_tokens/components/create_granular_token/personal_access_token_expiration_date.vue';
import { defaultDate } from '~/vue_shared/access_tokens/utils';

jest.mock('~/vue_shared/access_tokens/utils', () => ({
  defaultDate: jest.fn(),
}));

describe('PersonalAccessTokenExpirationDate', () => {
  let wrapper;

  const mockMinDate = '2025-12-11';
  const mockMaxDate = '2026-12-11';
  const mockDefaultDate = new Date('2026-01-09');

  const createComponent = ({ provide = {}, props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PersonalAccessTokenExpirationDate, {
      propsData: {
        ...props,
      },
      provide: {
        accessTokenMinDate: mockMinDate,
        accessTokenMaxDate: mockMaxDate,
        ...provide,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);

  beforeEach(() => {
    defaultDate.mockReturnValue(mockDefaultDate);

    createComponent();
  });

  it('renders the form group with correct label', () => {
    expect(findFormGroup().exists()).toBe(true);
    expect(findFormGroup().attributes('label')).toBe('Expiration date');
    expect(findFormGroup().attributes('label-for')).toBe('token-expiration');
  });

  it('renders the datepicker component with `minDate` and `maxDate`', () => {
    expect(findDatepicker().exists()).toBe(true);

    expect(findDatepicker().attributes('mindate')).toBe(new Date(mockMinDate).toString());
    expect(findDatepicker().attributes('maxdate')).toBe(new Date(mockMaxDate).toString());
  });

  describe('when `accessTokenMaxDate` is provided', () => {
    it('sets the default date', () => {
      expect(findDatepicker().attributes('defaultdate')).toBe(mockDefaultDate.toString());
    });

    it('does not show the clear button', () => {
      expect(findDatepicker().props('showClearButton')).toBe(false);
    });

    it('renders max token lifetime message', () => {
      jest.useFakeTimers({ legacyFakeTimers: false });
      jest.setSystemTime(new Date('2025-12-11'));

      createComponent({ mountFn: mountExtended });

      expect(wrapper.text()).toContain(
        'An administrator has set the maximum expiration date to 365 days (Dec 11, 2026).',
      );
    });
  });

  describe('when accessTokenMaxDate is not provided', () => {
    beforeEach(() => {
      createComponent({ provide: { accessTokenMaxDate: null } });
    });

    it('renders clear date message', () => {
      createComponent({ provide: { accessTokenMaxDate: null }, mountFn: mountExtended });

      expect(wrapper.text()).toContain(
        'Clear the date to create access tokens without expiration.',
      );
    });

    it('shows the clear button', () => {
      expect(findDatepicker().props('showClearButton')).toBe(true);
    });

    it('sets `maxDate` to null on datepicker', () => {
      expect(findDatepicker().props('maxDate')).toBe(null);
    });
  });

  describe('error handling', () => {
    it('passes error state to form group and datepicker', () => {
      createComponent({ props: { error: 'Expiration date is required.' } });

      expect(findFormGroup().attributes('invalid-feedback')).toBe('Expiration date is required.');

      expect(findDatepicker().props('state')).toBe(false);
    });
  });

  describe('events', () => {
    it('emits input event on mount with `defaultDate`', () => {
      expect(wrapper.emitted('input')).toHaveLength(1);
      expect(wrapper.emitted('input')[0]).toEqual([new Date(mockDefaultDate)]);
    });

    it('emits input event when datepicker value changes', async () => {
      const date = new Date('2025-12-15');
      await findDatepicker().vm.$emit('input', date);

      expect(wrapper.emitted('input')).toHaveLength(2);
      expect(wrapper.emitted('input')[1]).toEqual([date]);
    });
  });
});
