import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlFormInput, GlForm } from '@gitlab/ui';
import BoardSidebarIssueTitle from '~/boards/components/sidebar/board_sidebar_issue_title.vue';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import createFlash from '~/flash';
import { createStore } from '~/boards/stores';

const TEST_TITLE = 'New issue title';
const TEST_ISSUE_A = {
  id: 'gid://gitlab/Issue/1',
  iid: 8,
  title: 'Issue 1',
  referencePath: 'h/b#1',
};
const TEST_ISSUE_B = {
  id: 'gid://gitlab/Issue/2',
  iid: 9,
  title: 'Issue 2',
  referencePath: 'h/b#2',
};

jest.mock('~/flash');

describe('~/boards/components/sidebar/board_sidebar_issue_title.vue', () => {
  let wrapper;
  let store;

  afterEach(() => {
    localStorage.clear();
    wrapper.destroy();
    store = null;
    wrapper = null;
  });

  const createWrapper = (issue = TEST_ISSUE_A) => {
    store = createStore();
    store.state.issues = { [issue.id]: { ...issue } };
    store.dispatch('setActiveId', { id: issue.id });

    wrapper = shallowMount(BoardSidebarIssueTitle, {
      store,
      provide: {
        canUpdate: true,
      },
      stubs: {
        'board-editable-item': BoardEditableItem,
      },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findAlert = () => wrapper.find(GlAlert);
  const findFormInput = () => wrapper.find(GlFormInput);
  const findEditableItem = () => wrapper.find(BoardEditableItem);
  const findCancelButton = () => wrapper.find('[data-testid="cancel-button"]');
  const findTitle = () => wrapper.find('[data-testid="issue-title"]');
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');

  it('renders title and reference', () => {
    createWrapper();

    expect(findTitle().text()).toContain(TEST_ISSUE_A.title);
    expect(findCollapsed().text()).toContain(TEST_ISSUE_A.referencePath);
  });

  it('does not render alert', () => {
    createWrapper();

    expect(findAlert().exists()).toBe(false);
  });

  describe('when new title is submitted', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveIssueTitle').mockImplementation(() => {
        store.state.issues[TEST_ISSUE_A.id].title = TEST_TITLE;
      });
      findFormInput().vm.$emit('input', TEST_TITLE);
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders new title', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findTitle().text()).toContain(TEST_TITLE);
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueTitle).toHaveBeenCalledWith({
        title: TEST_TITLE,
        projectPath: 'h/b',
      });
    });
  });

  describe('when submitting and invalid title', () => {
    beforeEach(async () => {
      createWrapper();

      jest.spyOn(wrapper.vm, 'setActiveIssueTitle').mockImplementation(() => {});
      findFormInput().vm.$emit('input', '');
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await wrapper.vm.$nextTick();
    });

    it('commits change to the server', () => {
      expect(wrapper.vm.setActiveIssueTitle).not.toHaveBeenCalled();
    });
  });

  describe('when abandoning the form without saving', () => {
    beforeEach(async () => {
      createWrapper();

      wrapper.vm.$refs.sidebarItem.expand();
      findFormInput().vm.$emit('input', TEST_TITLE);
      findEditableItem().vm.$emit('off-click');
      await wrapper.vm.$nextTick();
    });

    it('does not collapses sidebar and shows alert', () => {
      expect(findCollapsed().isVisible()).toBe(false);
      expect(findAlert().exists()).toBe(true);
      expect(localStorage.getItem(`${TEST_ISSUE_A.id}/issue-title-pending-changes`)).toBe(
        TEST_TITLE,
      );
    });
  });

  describe('when accessing the form with pending changes', () => {
    beforeAll(() => {
      localStorage.setItem(`${TEST_ISSUE_A.id}/issue-title-pending-changes`, TEST_TITLE);

      createWrapper();
    });

    it('sets title, expands item and shows alert', async () => {
      expect(wrapper.vm.title).toBe(TEST_TITLE);
      expect(findCollapsed().isVisible()).toBe(false);
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('when cancel button is clicked', () => {
    beforeEach(async () => {
      createWrapper(TEST_ISSUE_B);

      jest.spyOn(wrapper.vm, 'setActiveIssueTitle').mockImplementation(() => {
        store.state.issues[TEST_ISSUE_B.id].title = TEST_TITLE;
      });
      findFormInput().vm.$emit('input', TEST_TITLE);
      findCancelButton().vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and render former title', () => {
      expect(wrapper.vm.setActiveIssueTitle).not.toHaveBeenCalled();
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findTitle().text()).toBe(TEST_ISSUE_B.title);
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      createWrapper(TEST_ISSUE_B);

      jest.spyOn(wrapper.vm, 'setActiveIssueTitle').mockImplementation(() => {
        throw new Error(['failed mutation']);
      });
      findFormInput().vm.$emit('input', 'Invalid title');
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await wrapper.vm.$nextTick();
    });

    it('collapses sidebar and renders former issue title', () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findTitle().text()).toContain(TEST_ISSUE_B.title);
      expect(createFlash).toHaveBeenCalled();
    });
  });
});
