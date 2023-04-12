import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import { TYPE_ISSUE } from '~/issues/constants';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSeverityWidget from '~/sidebar/components/severity/sidebar_severity_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import { mockActiveIssue, mockIssue, rawIssue } from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);
describe('BoardContentSidebar', () => {
  let wrapper;
  let store;

  const mockSetActiveBoardItemResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setActiveBoardItem: mockSetActiveBoardItemResolver,
    },
  });

  const createStore = ({ mockGetters = {}, mockActions = {} } = {}) => {
    store = new Vuex.Store({
      state: {
        sidebarType: ISSUABLE,
        issues: { [mockIssue.id]: { ...mockIssue, epic: null } },
        activeId: mockIssue.id,
      },
      getters: {
        activeBoardItem: () => {
          return { ...mockActiveIssue, epic: null };
        },
        ...mockGetters,
      },
      actions: mockActions,
    });
  };

  const createComponent = ({ isApolloBoard = false } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: rawIssue,
      },
    });

    wrapper = shallowMountExtended(BoardContentSidebar, {
      apolloProvider: mockApollo,
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: 1,
        issuableType: TYPE_ISSUE,
        isGroupBoard: false,
        isApolloBoard,
      },
      store,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: '<div><slot name="header"></slot><slot></slot></div>',
        }),
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent();
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.findComponent(GlDrawer).exists()).toBe(true);
  });

  it('confirms we render MountingPortal', () => {
    expect(wrapper.findComponent(MountingPortal).props()).toMatchObject({
      mountTo: '#js-right-sidebar-portal',
      append: true,
      name: 'board-content-sidebar',
    });
  });

  it('does not render GlDrawer when no active item is set', async () => {
    createStore({ mockGetters: { activeBoardItem: () => ({ id: '', iid: '' }) } });
    createComponent();

    await nextTick();

    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
  });

  it('applies an open attribute', () => {
    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(true);
  });

  it('renders SidebarTodoWidget', () => {
    expect(wrapper.findComponent(SidebarTodoWidget).exists()).toBe(true);
  });

  it('renders SidebarLabelsWidget', () => {
    expect(wrapper.findComponent(SidebarLabelsWidget).exists()).toBe(true);
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

  it('does not render SidebarSeverityWidget', () => {
    expect(wrapper.findComponent(SidebarSeverityWidget).exists()).toBe(false);
  });

  it('does not render SidebarHealthStatusWidget', async () => {
    const SidebarHealthStatusWidget = (
      await import('ee_component/sidebar/components/health_status/sidebar_health_status_widget.vue')
    ).default;
    expect(wrapper.findComponent(SidebarHealthStatusWidget).exists()).toBe(false);
  });

  it('does not render SidebarWeightWidget', async () => {
    const SidebarWeightWidget = (
      await import('ee_component/sidebar/components/weight/sidebar_weight_widget.vue')
    ).default;
    expect(wrapper.findComponent(SidebarWeightWidget).exists()).toBe(false);
  });

  describe('when we emit close', () => {
    let toggleBoardItem;

    beforeEach(() => {
      toggleBoardItem = jest.fn();
      createStore({ mockActions: { toggleBoardItem } });
      createComponent();
    });

    it('calls toggleBoardItem with correct parameters', () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');

      expect(toggleBoardItem).toHaveBeenCalledTimes(1);
      expect(toggleBoardItem).toHaveBeenCalledWith(expect.any(Object), {
        boardItem: { ...mockActiveIssue, epic: null },
        sidebarType: ISSUABLE,
      });
    });
  });

  describe('incident sidebar', () => {
    beforeEach(() => {
      createStore({
        mockGetters: { activeBoardItem: () => ({ ...mockIssue, epic: null, type: 'INCIDENT' }) },
      });
      createComponent();
    });

    it('renders SidebarSeverityWidget', () => {
      expect(wrapper.findComponent(SidebarSeverityWidget).exists()).toBe(true);
    });
  });

  describe('Apollo boards', () => {
    beforeEach(async () => {
      createStore();
      createComponent({ isApolloBoard: true });
      await nextTick();
    });

    it('calls setActiveBoardItemMutation on close', async () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');

      await waitForPromises();

      expect(mockSetActiveBoardItemResolver).toHaveBeenCalledWith(
        {},
        {
          boardItem: null,
        },
        expect.anything(),
        expect.anything(),
      );
    });
  });
});
