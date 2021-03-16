import { GlLoadingIcon, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockMilestone as TEST_MILESTONE } from 'jest/boards/mock_data';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import BoardSidebarMilestoneSelect from '~/boards/components/sidebar/board_sidebar_milestone_select.vue';
import { createStore } from '~/boards/stores';
import createFlash from '~/flash';

const TEST_ISSUE = { id: 'gid://gitlab/Issue/1', iid: 9, referencePath: 'h/b#2' };

jest.mock('~/flash');

describe('~/boards/components/sidebar/board_sidebar_milestone_select.vue', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    store = null;
    wrapper = null;
  });

  const createWrapper = ({ milestone = null, loading = false } = {}) => {
    store = createStore();
    store.state.boardItems = { [TEST_ISSUE.id]: { ...TEST_ISSUE, milestone } };
    store.state.activeId = TEST_ISSUE.id;

    wrapper = shallowMount(BoardSidebarMilestoneSelect, {
      store,
      provide: {
        canUpdate: true,
      },
      data: () => ({
        milestones: [TEST_MILESTONE],
      }),
      stubs: {
        'board-editable-item': BoardEditableItem,
      },
      mocks: {
        $apollo: {
          loading,
        },
      },
    });
  };

  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findDropdown = () => wrapper.find(GlDropdown);
  const findBoardEditableItem = () => wrapper.find(BoardEditableItem);
  const findDropdownItem = () => wrapper.find('[data-testid="milestone-item"]');
  const findUnsetMilestoneItem = () => wrapper.find('[data-testid="no-milestone-item"]');
  const findNoMilestonesFoundItem = () => wrapper.find('[data-testid="no-milestones-found"]');

  describe('when not editing', () => {
    it('opens the milestone dropdown on clicking edit', async () => {
      createWrapper();
      wrapper.vm.$refs.dropdown.show = jest.fn();

      await findBoardEditableItem().vm.$emit('open');

      expect(wrapper.vm.$refs.dropdown.show).toHaveBeenCalledTimes(1);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      createWrapper();
      jest.spyOn(wrapper.vm.$refs.sidebarItem, 'collapse');
    });

    it('collapses BoardEditableItem on clicking edit', async () => {
      await findBoardEditableItem().vm.$emit('close');

      expect(wrapper.vm.$refs.sidebarItem.collapse).toHaveBeenCalledTimes(1);
    });

    it('collapses BoardEditableItem on hiding dropdown', async () => {
      await findDropdown().vm.$emit('hide');

      expect(wrapper.vm.$refs.sidebarItem.collapse).toHaveBeenCalledTimes(1);
    });
  });

  it('renders "None" when no milestone is selected', () => {
    createWrapper();

    expect(findCollapsed().text()).toBe('None');
  });

  it('renders milestone title when set', () => {
    createWrapper({ milestone: TEST_MILESTONE });

    expect(findCollapsed().text()).toContain(TEST_MILESTONE.title);
  });

  it('shows loader while Apollo is loading', async () => {
    createWrapper({ milestone: TEST_MILESTONE, loading: true });

    expect(findLoader().exists()).toBe(true);
  });

  it('shows message when error or no milestones found', async () => {
    createWrapper();

    await wrapper.setData({ milestones: [] });

    expect(findNoMilestonesFoundItem().text()).toBe('No milestones found');
  });

  describe('when milestone is selected', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveIssueMilestone').mockImplementation(() => {
        store.state.boardItems[TEST_ISSUE.id].milestone = TEST_MILESTONE;
      });
      findDropdownItem().vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders selected milestone', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toContain(TEST_MILESTONE.title);
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueMilestone).toHaveBeenCalledWith({
        milestoneId: TEST_MILESTONE.id,
        projectPath: 'h/b',
      });
    });
  });

  describe('when milestone is set to "None"', () => {
    beforeEach(async () => {
      createWrapper({ milestone: TEST_MILESTONE });

      jest.spyOn(wrapper.vm, 'setActiveIssueMilestone').mockImplementation(() => {
        store.state.boardItems[TEST_ISSUE.id].milestone = null;
      });
      findUnsetMilestoneItem().vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders "None"', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toBe('None');
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueMilestone).toHaveBeenCalledWith({
        milestoneId: null,
        projectPath: 'h/b',
      });
    });
  });

  describe('when the mutation fails', () => {
    const testMilestone = { id: '1', title: 'Former milestone' };

    beforeEach(async () => {
      createWrapper({ milestone: testMilestone });

      jest.spyOn(wrapper.vm, 'setActiveIssueMilestone').mockImplementation(() => {
        throw new Error(['failed mutation']);
      });
      findDropdownItem().vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders former milestone', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findCollapsed().text()).toContain(testMilestone.title);
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
