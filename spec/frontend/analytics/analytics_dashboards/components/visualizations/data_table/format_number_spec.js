import { shallowMount } from '@vue/test-utils';
import FormatNumber from '~/analytics/analytics_dashboards/components/visualizations/data_table/format_number.vue';

describe('FormatNumber', () => {
  let wrapper;

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(FormatNumber, {
      propsData,
    });
  };

  it('renders the number with no decimals by default', () => {
    createWrapper({ value: 10.164 });
    expect(wrapper.text()).toEqual('10');
  });

  it('renders the number of decimals specified by fractionDigits', () => {
    createWrapper({ value: 10.164, fractionDigits: 2 });
    expect(wrapper.text()).toEqual('10.16');
  });

  it.each([null, undefined])('renders - when value is %s', (value) => {
    createWrapper({ value });
    expect(wrapper.text()).toEqual('-');
  });
});
