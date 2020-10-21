import { shallowMount } from '@vue/test-utils';
import BoardConfigurationOptions from '~/boards/components/board_configuration_options.vue';

describe('BoardConfigurationOptions', () => {
  let wrapper;
  const board = { hide_backlog_list: false, hide_closed_list: false };

  const defaultProps = {
    currentBoard: board,
    board,
    isNewForm: false,
  };

  const createComponent = () => {
    wrapper = shallowMount(BoardConfigurationOptions, {
      propsData: { ...defaultProps },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const backlogListCheckbox = el => el.find('[data-testid="backlog-list-checkbox"]');
  const closedListCheckbox = el => el.find('[data-testid="closed-list-checkbox"]');

  const checkboxAssert = (backlogCheckbox, closedCheckbox) => {
    expect(backlogListCheckbox(wrapper).attributes('checked')).toEqual(
      backlogCheckbox ? undefined : 'true',
    );
    expect(closedListCheckbox(wrapper).attributes('checked')).toEqual(
      closedCheckbox ? undefined : 'true',
    );
  };

  it.each`
    backlogCheckboxValue | closedCheckboxValue
    ${true}              | ${true}
    ${true}              | ${false}
    ${false}             | ${true}
    ${false}             | ${false}
  `(
    'renders two checkbox when one is $backlogCheckboxValue and other is $closedCheckboxValue',
    async ({ backlogCheckboxValue, closedCheckboxValue }) => {
      await wrapper.setData({
        hideBacklogList: backlogCheckboxValue,
        hideClosedList: closedCheckboxValue,
      });

      return wrapper.vm.$nextTick().then(() => {
        checkboxAssert(backlogCheckboxValue, closedCheckboxValue);
      });
    },
  );
});
