import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiVariablePopover from '~/ci_variable_list/components/ci_variable_popover.vue';
import mockData from '../services/mock_data';

describe('Ci Variable Popover', () => {
  let wrapper;

  const defaultProps = {
    target: 'ci-variable-value-22',
    value: mockData.mockPemCert,
    tooltipText: 'Copy value',
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMount(CiVariablePopover, {
      propsData: { ...props },
    });
  };

  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays max count plus ... when character count is over 95', () => {
    expect(wrapper.text()).toHaveLength(98);
  });

  it('copies full value to clipboard', () => {
    expect(findButton().attributes('data-clipboard-text')).toEqual(mockData.mockPemCert);
  });

  it('displays full value when count is less than max count', () => {
    createComponent({
      target: 'ci-variable-value-22',
      value: 'test_variable_value',
      tooltipText: 'Copy value',
    });
    expect(wrapper.text()).toEqual('test_variable_value');
  });
});
