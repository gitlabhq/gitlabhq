import { shallowMount } from '@vue/test-utils';
import { GlDatepicker } from '@gitlab/ui';
import BoardSidebarDueDate from '~/boards/components/sidebar/board_sidebar_due_date.vue';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import { createStore } from '~/boards/stores';
import createFlash from '~/flash';

const TEST_DUE_DATE = '2020-02-20';
const TEST_FORMATTED_DUE_DATE = 'Feb 20, 2020';
const TEST_PARSED_DATE = new Date(2020, 1, 20);
const TEST_ISSUE = { id: 'gid://gitlab/Issue/1', iid: 9, dueDate: null, referencePath: 'h/b#2' };

jest.mock('~/flash');

describe('~/boards/components/sidebar/board_sidebar_due_date.vue', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    store = null;
    wrapper = null;
  });

  const createWrapper = ({ dueDate = null } = {}) => {
    store = createStore();
    store.state.issues = { [TEST_ISSUE.id]: { ...TEST_ISSUE, dueDate } };
    store.state.activeId = TEST_ISSUE.id;

    wrapper = shallowMount(BoardSidebarDueDate, {
      store,
      provide: {
        canUpdate: true,
      },
      stubs: {
        'board-editable-item': BoardEditableItem,
      },
    });
  };

  const findDatePicker = () => wrapper.find(GlDatepicker);
  const findResetButton = () => wrapper.find('[data-testid="reset-button"]');
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');

  it('renders "None" when no due date is set', () => {
    createWrapper();

    expect(findCollapsed().text()).toBe('None');
    expect(findResetButton().exists()).toBe(false);
  });

  it('renders formatted due date with reset button when set', () => {
    createWrapper({ dueDate: TEST_DUE_DATE });

    expect(findCollapsed().text()).toContain(TEST_FORMATTED_DUE_DATE);
    expect(findResetButton().exists()).toBe(true);
  });

  describe('when due date is submitted', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveIssueDueDate').mockImplementation(() => {
        store.state.issues[TEST_ISSUE.id].dueDate = TEST_DUE_DATE;
      });
      findDatePicker().vm.$emit('input', TEST_PARSED_DATE);
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders formatted due date with reset button', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toContain(TEST_FORMATTED_DUE_DATE);
      expect(findResetButton().exists()).toBe(true);
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueDueDate).toHaveBeenCalledWith({
        dueDate: TEST_DUE_DATE,
        projectPath: 'h/b',
      });
    });
  });

  describe('when due date is cleared', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveIssueDueDate').mockImplementation(() => {
        store.state.issues[TEST_ISSUE.id].dueDate = null;
      });
      findDatePicker().vm.$emit('clear');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders "None"', () => {
      expect(wrapper.vm.setActiveIssueDueDate).toHaveBeenCalled();
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toBe('None');
    });
  });

  describe('when due date is resetted', () => {
    beforeEach(async () => {
      createWrapper({ dueDate: TEST_DUE_DATE });

      jest.spyOn(wrapper.vm, 'setActiveIssueDueDate').mockImplementation(() => {
        store.state.issues[TEST_ISSUE.id].dueDate = null;
      });
      findResetButton().vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders "None"', () => {
      expect(wrapper.vm.setActiveIssueDueDate).toHaveBeenCalled();
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toBe('None');
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      createWrapper({ dueDate: TEST_DUE_DATE });

      jest.spyOn(wrapper.vm, 'setActiveIssueDueDate').mockImplementation(() => {
        throw new Error(['failed mutation']);
      });
      findDatePicker().vm.$emit('input', 'Invalid date');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders former issue due date', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toContain(TEST_FORMATTED_DUE_DATE);
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
