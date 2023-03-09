import { shallowMount } from '@vue/test-utils';
import { GlDatepicker } from '@gitlab/ui';
import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import { getDateInFuture } from '~/lib/utils/datetime_utility';

describe('~/access_tokens/components/expires_at_field', () => {
  let wrapper;

  const defaultPropsData = {
    inputAttrs: {
      id: 'personal_access_token_expires_at',
      name: 'personal_access_token[expires_at]',
      placeholder: 'YYYY-MM-DD',
    },
  };

  const findDatepicker = () => wrapper.findComponent(GlDatepicker);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ExpiresAtField, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  it('should render datepicker with input info', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should set the date pickers minimum date', () => {
    const minDate = new Date('1970-01-01');

    createComponent({ minDate });

    expect(findDatepicker().props('minDate')).toStrictEqual(minDate);
  });

  it('should set the date pickers maximum date', () => {
    const maxDate = new Date('1970-01-01');

    createComponent({ maxDate });

    expect(findDatepicker().props('maxDate')).toStrictEqual(maxDate);
  });

  it('should set the default expiration date to be 30 days', () => {
    const today = new Date();
    const future = getDateInFuture(today, 30);
    createComponent();

    expect(findDatepicker().props('defaultDate')).toStrictEqual(future);
  });

  it('should set the default expiration date to be 365 days', () => {
    const offset = 365;
    const today = new Date();
    const future = getDateInFuture(today, offset);
    createComponent({ defaultDateOffset: offset });

    expect(findDatepicker().props('defaultDate')).toStrictEqual(future);
  });

  it('should set the default expiration date to maxDate, ignoring defaultDateOffset', () => {
    const maxDate = new Date();
    createComponent({ maxDate, defaultDateOffset: 2 });

    expect(findDatepicker().props('defaultDate')).toStrictEqual(maxDate);
  });
});
