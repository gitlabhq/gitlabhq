import { shallowMount } from '@vue/test-utils';
import BoardConfigurationOptions from '~/boards/components/board_configuration_options.vue';

describe('BoardConfigurationOptions', () => {
  let wrapper;

  const defaultProps = {
    hideBacklogList: false,
    hideClosedList: false,
    readonly: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BoardConfigurationOptions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const backlogListCheckbox = () => wrapper.find('[data-testid="backlog-list-checkbox"]');
  const closedListCheckbox = () => wrapper.find('[data-testid="closed-list-checkbox"]');

  const checkboxAssert = (backlogCheckbox, closedCheckbox) => {
    expect(backlogListCheckbox().attributes('checked')).toEqual(
      backlogCheckbox ? undefined : 'true',
    );
    expect(closedListCheckbox().attributes('checked')).toEqual(closedCheckbox ? undefined : 'true');
  };

  it.each`
    backlogCheckboxValue | closedCheckboxValue
    ${true}              | ${true}
    ${true}              | ${false}
    ${false}             | ${true}
    ${false}             | ${false}
  `(
    'renders two checkbox when one is $backlogCheckboxValue and other is $closedCheckboxValue',
    ({ backlogCheckboxValue, closedCheckboxValue }) => {
      createComponent({
        hideBacklogList: backlogCheckboxValue,
        hideClosedList: closedCheckboxValue,
      });
      checkboxAssert(backlogCheckboxValue, closedCheckboxValue);
    },
  );

  it('emits a correct value on backlog checkbox change', () => {
    createComponent();

    backlogListCheckbox().vm.$emit('change');

    expect(wrapper.emitted('update:hideBacklogList')).toEqual([[true]]);
  });

  it('emits a correct value on closed checkbox change', () => {
    createComponent();

    closedListCheckbox().vm.$emit('change');

    expect(wrapper.emitted('update:hideClosedList')).toEqual([[true]]);
  });

  it('renders checkboxes disabled when user does not have edit rights', () => {
    createComponent({ readonly: true });

    expect(closedListCheckbox().attributes('disabled')).toBeDefined();
    expect(backlogListCheckbox().attributes('disabled')).toBeDefined();
  });

  it('renders checkboxes enabled when user has edit rights', () => {
    createComponent();

    expect(closedListCheckbox().attributes('disabled')).toBeUndefined();
    expect(backlogListCheckbox().attributes('disabled')).toBeUndefined();
  });
});
