import { GlDrawer } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { MountingPortal } from 'portal-vue';
import Vuex from 'vuex';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import { stubComponent } from 'helpers/stub_component';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import { mockActiveIssue, mockIssue, mockIssueGroupPath, mockIssueProjectPath } from '../mock_data';

describe('BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createStore = ({ mockGetters = {}, mockActions = {} } = {}) => {
    store = new Vuex.Store({
      state: {
        sidebarType: ISSUABLE,
        issues: { [mockIssue.id]: { ...mockIssue, epic: null } },
        activeId: mockIssue.id,
        issuableType: 'issue',
      },
      getters: {
        activeBoardItem: () => {
          return { ...mockActiveIssue, epic: null };
        },
        groupPathForActiveIssue: () => mockIssueGroupPath,
        projectPathForActiveIssue: () => mockIssueProjectPath,
        isSidebarOpen: () => true,
        ...mockGetters,
      },
      actions: mockActions,
    });
  };

  const createComponent = () => {
    /*
      Dynamically imported components (in our case ee imports)
      aren't stubbed automatically in VTU v1:
      https://github.com/vuejs/vue-test-utils/issues/1279.

      This requires us to additionally mock apollo or vuex stores.
    */
    wrapper = shallowMount(BoardContentSidebar, {
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: 1,
      },
      store,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: '<div><slot name="header"></slot><slot></slot></div>',
        }),
      },
      mocks: {
        $apollo: {
          queries: {
            participants: {
              loading: false,
            },
            currentIteration: {
              loading: false,
            },
            iterations: {
              loading: false,
            },
            attributesList: {
              loading: false,
            },
          },
        },
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.findComponent(GlDrawer).exists()).toBe(true);
  });

  it('confirms we render MountingPortal', () => {
    expect(wrapper.find(MountingPortal).props()).toMatchObject({
      mountTo: '#js-right-sidebar-portal',
      append: true,
      name: 'board-content-sidebar',
    });
  });

  it('does not render GlDrawer when isSidebarOpen is false', () => {
    createStore({ mockGetters: { isSidebarOpen: () => false } });
    createComponent();

    expect(wrapper.findComponent(GlDrawer).exists()).toBe(false);
  });

  it('applies an open attribute', () => {
    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(true);
  });

  it('renders SidebarTodoWidget', () => {
    expect(wrapper.findComponent(SidebarTodoWidget).exists()).toBe(true);
  });

  it('renders BoardSidebarLabelsSelect', () => {
    expect(wrapper.findComponent(BoardSidebarLabelsSelect).exists()).toBe(true);
  });

  it('renders BoardSidebarTitle', () => {
    expect(wrapper.findComponent(BoardSidebarTitle).exists()).toBe(true);
  });

  it('renders SidebarDateWidget', () => {
    expect(wrapper.findComponent(SidebarDateWidget).exists()).toBe(true);
  });

  it('renders BoardSidebarSubscription', () => {
    expect(wrapper.findComponent(SidebarSubscriptionsWidget).exists()).toBe(true);
  });

  it('renders SidebarDropdownWidget for milestones', () => {
    expect(wrapper.findComponent(SidebarDropdownWidget).exists()).toBe(true);
    expect(wrapper.findComponent(SidebarDropdownWidget).props('issuableAttribute')).toEqual(
      'milestone',
    );
  });

  describe('when we emit close', () => {
    let toggleBoardItem;

    beforeEach(() => {
      toggleBoardItem = jest.fn();
      createStore({ mockActions: { toggleBoardItem } });
      createComponent();
    });

    it('calls toggleBoardItem with correct parameters', async () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');

      expect(toggleBoardItem).toHaveBeenCalledTimes(1);
      expect(toggleBoardItem).toHaveBeenCalledWith(expect.any(Object), {
        boardItem: { ...mockActiveIssue, epic: null },
        sidebarType: ISSUABLE,
      });
    });
  });
});
