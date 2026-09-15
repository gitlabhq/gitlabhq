import { shallowMount } from '@vue/test-utils';
import FormatText from '~/analytics/analytics_dashboards/components/visualizations/data_table/format_text.vue';

describe('FormatText', () => {
  let wrapper;

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(FormatText, {
      propsData: { value: '1.4×', ...propsData },
    });
  };

  const findText = () => wrapper.find('span');

  it('renders a string value', () => {
    createWrapper();

    expect(wrapper.text()).toBe('1.4×');
  });

  it('renders a numeric value', () => {
    createWrapper({ value: 42 });

    expect(wrapper.text()).toBe('42');
  });

  it('does not bold the value by default', () => {
    createWrapper();

    expect(findText().classes()).not.toContain('gl-font-bold');
  });

  it('bolds the value when `bold` is true', () => {
    createWrapper({ bold: true });

    expect(findText().classes()).toContain('gl-font-bold');
  });
});
