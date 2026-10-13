import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestTitleActions from '~/merge_requests/components/merge_request_title_actions.vue';
import PanelActionsPortal from '~/vue_shared/components/panel_actions_portal.vue';
import CodeDropdown from '~/merge_requests/components/code_dropdown.vue';
import MrMoreDropdown from '~/vue_shared/components/mr_more_dropdown.vue';
import TodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';

jest.mock('~/behaviors/shortcuts/shortcuts_disabled');

describe('MergeRequestTitleActions', () => {
  let wrapper;

  const defaultProps = {
    projectPath: 'group/project',
    iid: '1',
    id: 5,
    canUpdate: true,
    isSignedIn: true,
    editPath: '/group/project/-/merge_requests/1/edit',
    codeDropdownProps: { patchesPath: '/patch', plainDiffPath: '/diff' },
    moreDropdownProps: {
      mr: { iid: 1, draft: false, target_project_id: 2 },
      isCurrentUser: false,
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(MergeRequestTitleActions, {
      propsData: { ...defaultProps, ...props },
      stubs: { PanelActionsPortal: true },
    });
  };

  beforeEach(() => {
    keyboardShortcutsDisabled.mockReturnValue(false);
  });

  const findPanelActionsPortal = () => wrapper.findComponent(PanelActionsPortal);
  const findEditButton = () => wrapper.findByTestId('edit-title-button');
  const findCodeDropdown = () => wrapper.findComponent(CodeDropdown);
  const findMoreDropdown = () => wrapper.findComponent(MrMoreDropdown);
  const findTodoWidget = () => wrapper.findComponent(TodoWidget);
  const findSubscriptionsWidget = () => wrapper.findComponent(SubscriptionsWidget);

  it('renders actions inside a PanelActionsPortal', () => {
    createComponent();

    expect(findPanelActionsPortal().exists()).toBe(true);
  });

  it('renders the code dropdown as the first action', () => {
    createComponent();

    expect(findCodeDropdown().props('patchesPath')).toBe('/patch');
  });

  it('does not render the code dropdown when no props are provided', () => {
    createComponent({ codeDropdownProps: null });

    expect(findCodeDropdown().exists()).toBe(false);
  });

  it('renders the edit button pointing at the edit path when the user can update', () => {
    createComponent();

    expect(findEditButton().attributes('href')).toBe(defaultProps.editPath);
  });

  it('does not render the edit button when the user cannot update', () => {
    createComponent({ canUpdate: false });

    expect(findEditButton().exists()).toBe(false);
  });

  it('has the js-issuable-edit class for the keyboard shortcut handler', () => {
    createComponent();

    expect(findEditButton().classes()).toContain('js-issuable-edit');
  });

  it('shows the shortcut hint when shortcuts are enabled', () => {
    createComponent();

    expect(findEditButton().attributes('aria-keyshortcuts')).toBe('e');
    expect(findEditButton().attributes('title')).toContain('<kbd');
  });

  it('hides the shortcut hint when shortcuts are disabled', () => {
    keyboardShortcutsDisabled.mockReturnValue(true);
    createComponent();

    expect(findEditButton().attributes('aria-keyshortcuts')).toBeUndefined();
    expect(findEditButton().attributes('title')).toBe('Edit merge request');
  });

  describe('when signed in', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the to-do widget with a GraphQL id', () => {
      expect(findTodoWidget().props('issuableId')).toBe('gid://gitlab/MergeRequest/5');
    });

    it('renders the subscriptions widget', () => {
      expect(findSubscriptionsWidget().props('iid')).toBe('1');
    });

    it('renders the more dropdown', () => {
      expect(findMoreDropdown().exists()).toBe(true);
    });
  });

  describe('when signed out', () => {
    beforeEach(() => {
      createComponent({ isSignedIn: false });
    });

    it('does not render the to-do, subscriptions, or more dropdown', () => {
      expect(findTodoWidget().exists()).toBe(false);
      expect(findSubscriptionsWidget().exists()).toBe(false);
      expect(findMoreDropdown().exists()).toBe(false);
    });
  });
});
