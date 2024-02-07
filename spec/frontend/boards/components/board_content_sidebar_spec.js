import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { TYPE_ISSUE } from '~/issues/constants';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSeverityWidget from '~/sidebar/components/severity/sidebar_severity_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import { rawIssue } from '../mock_data';

Vue.use(VueApollo);
describe('BoardContentSidebar', () => {
  let wrapper;

  const mockSetActiveBoardItemResolver = jest.fn();
  const mockApollo = createMockApollo([], {
    Mutation: {
      setActiveBoardItem: mockSetActiveBoardItemResolver,
    },
  });

  const createComponent = ({ issuable = rawIssue } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: { ...issuable, listId: 'gid://gitlab/List/1' },
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
      },
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: '<div><slot name="header"></slot><slot></slot></div>',
        }),
      },
    });
  };

  beforeEach(() => {
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
    createComponent({ issuable: {} });

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
    beforeEach(() => {
      createComponent();
    });

    it('calls setActiveBoardItemMutation on close', async () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');

      await waitForPromises();

      expect(mockSetActiveBoardItemResolver).toHaveBeenCalledWith(
        {},
        {
          boardItem: null,
          listId: null,
        },
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('incident sidebar', () => {
    beforeEach(() => {
      createComponent({ issuable: { ...rawIssue, epic: null, type: 'INCIDENT' } });
    });

    it('renders SidebarSeverityWidget', () => {
      expect(wrapper.findComponent(SidebarSeverityWidget).exists()).toBe(true);
    });
  });
});
