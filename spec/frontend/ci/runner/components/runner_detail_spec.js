import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerDetail from '~/ci/runner/components/runner_detail.vue';

describe('RunnerDetail', () => {
  let wrapper;
  const createWrapper = ({ props, slots }) => {
    wrapper = shallowMountExtended(RunnerDetail, {
      propsData: props,
      slots,
    });
  };
  const findLabelText = () => wrapper.findByTestId('label-slot').text();
  const findValueText = () => wrapper.findByTestId('value-slot').text();

  it('renders the label slot when a label prop is provided', () => {
    createWrapper({ props: { label: 'Field Name' } });

    expect(findLabelText()).toBe('Field Name');
  });

  it('does not render the label slot when no label prop is provided', () => {
    createWrapper({ props: {} });

    expect(findLabelText()).toBe('');
  });

  it('renders the value slot when a value prop is provided', () => {
    createWrapper({ props: { value: 'testValue' } });

    expect(findValueText()).toBe('testValue');
  });

  it('renders the emptyValue when no value prop is provided', () => {
    createWrapper({ props: {} });

    expect(findValueText()).toBe('None');
  });

  it('renders both the label and value slots when both label and value props are provided', () => {
    createWrapper({ props: { label: 'Field Name', value: 'testValue' } });

    expect(findLabelText()).toBe('Field Name');
    expect(findValueText()).toBe('testValue');
  });

  it('renders the label slot when a label slot is provided', () => {
    createWrapper({
      slots: {
        label: 'Label Slot Test',
      },
    });

    expect(findLabelText()).toBe('Label Slot Test');
  });

  it('does not render the label slot when no label slot is provided', () => {
    createWrapper({
      slots: {},
    });

    expect(findLabelText()).toBe('');
  });

  it('renders the value slot when a value slot is provided', () => {
    createWrapper({
      slots: {
        value: 'Value Slot Test',
      },
    });

    expect(findValueText()).toBe('Value Slot Test');
  });

  it('renders the emptyValue when no value slot is provided', () => {
    createWrapper({
      slots: {},
    });

    expect(findValueText()).toBe('None');
  });

  it('renders both the label and value slots when both label and value slots are provided', () => {
    createWrapper({ slots: { label: 'Label Slot Test', value: 'Value Slot Test' } });

    expect(findLabelText()).toBe('Label Slot Test');
    expect(findValueText()).toBe('Value Slot Test');
  });
});
