import { GlDrawer, GlLabel, GlModal, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { MountingPortal } from 'portal-vue';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import { inactiveId, LIST } from '~/boards/constants';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import actions from '~/boards/stores/actions';
import getters from '~/boards/stores/getters';
import mutations from '~/boards/stores/mutations';
import sidebarEventHub from '~/sidebar/event_hub';
import { mockLabelList, destroyBoardListMutationResponse } from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('BoardSettingsSidebar', () => {
  let wrapper;
  let mockApollo;
  const labelTitle = mockLabelList.label.title;
  const labelColor = mockLabelList.label.color;
  const listId = mockLabelList.id;
  const modalID = 'board-settings-sidebar-modal';

  const destroyBoardListMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(destroyBoardListMutationResponse);

  const createComponent = ({
    canAdminList = false,
    list = {},
    sidebarType = LIST,
    activeId = inactiveId,
    isApolloBoard = false,
  } = {}) => {
    const boardLists = {
      [listId]: list,
    };
    const store = new Vuex.Store({
      state: { sidebarType, activeId, boardLists },
      getters,
      mutations,
      actions,
    });

    mockApollo = createMockApollo([
      [destroyBoardListMutation, destroyBoardListMutationHandlerSuccess],
    ]);

    wrapper = extendedWrapper(
      shallowMount(BoardSettingsSidebar, {
        store,
        apolloProvider: mockApollo,
        provide: {
          canAdminList,
          scopedLabelsAvailable: false,
          isIssueBoard: true,
          boardType: 'group',
          issuableType: 'issue',
          isApolloBoard,
        },
        propsData: {
          listId: list.id || '',
          boardId: 'gid://gitlab/Board/1',
          list,
          queryVariables: {},
        },
        directives: {
          GlModal: createMockDirective('gl-modal'),
        },
        stubs: {
          GlDrawer: stubComponent(GlDrawer, {
            template: '<div><slot name="header"></slot><slot></slot></div>',
          }),
        },
      }),
    );

    // Necessary for cache update
    mockApollo.clients.defaultClient.cache.updateQuery = jest.fn();
  };
  const findLabel = () => wrapper.findComponent(GlLabel);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findModal = () => wrapper.findComponent(GlModal);
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('finds a MountingPortal component', () => {
    createComponent();

    expect(wrapper.findComponent(MountingPortal).props()).toMatchObject({
      mountTo: '#js-right-sidebar-portal',
      append: true,
      name: 'board-settings-sidebar',
    });
  });

  describe('when sidebarType is "list"', () => {
    it('finds a GlDrawer component', () => {
      createComponent();

      expect(findDrawer().exists()).toBe(true);
    });

    describe('on close', () => {
      it('closes the sidebar', async () => {
        createComponent();

        findDrawer().vm.$emit('close');

        await nextTick();

        expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
      });

      it('closes the sidebar when emitting the correct event', async () => {
        createComponent();

        sidebarEventHub.$emit('sidebar.closeAll');

        await nextTick();

        expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
      });
    });

    describe('when activeId is zero', () => {
      it('renders GlDrawer with open false', () => {
        createComponent();

        expect(findDrawer().props('open')).toBe(false);
      });
    });

    describe('when activeId is greater than zero', () => {
      it('renders GlDrawer with open true', () => {
        createComponent({ list: mockLabelList, activeId: listId });

        expect(findDrawer().props('open')).toBe(true);
      });
    });

    describe('when activeId is in state', () => {
      it('renders label title', () => {
        createComponent({ list: mockLabelList, activeId: listId });

        expect(findLabel().props('title')).toBe(labelTitle);
      });

      it('renders label background color', () => {
        createComponent({ list: mockLabelList, activeId: listId });

        expect(findLabel().props('backgroundColor')).toBe(labelColor);
      });
    });

    describe('when activeId is not in state', () => {
      it('does not render GlLabel', () => {
        createComponent({ list: mockLabelList });

        expect(findLabel().exists()).toBe(false);
      });
    });
  });

  describe('when sidebarType is not List', () => {
    it('does not render GlDrawer', () => {
      createComponent({ sidebarType: '' });

      expect(findDrawer().props('open')).toBe(false);
    });
  });

  it('does not render "Remove list" when user cannot admin the boards list', () => {
    createComponent();

    expect(findRemoveButton().exists()).toBe(false);
  });

  describe('when user can admin the boards list', () => {
    it('renders "Remove list" button', () => {
      createComponent({ canAdminList: true, activeId: listId, list: mockLabelList });

      expect(findRemoveButton().exists()).toBe(true);
    });

    it('removes the list', () => {
      createComponent({
        canAdminList: true,
        activeId: listId,
        list: mockLabelList,
        isApolloBoard: true,
      });

      findRemoveButton().vm.$emit('click');

      wrapper.findComponent(GlModal).vm.$emit('primary');

      expect(destroyBoardListMutationHandlerSuccess).toHaveBeenCalled();
    });

    it('has the correct ID on the button', () => {
      createComponent({ canAdminList: true, activeId: listId, list: mockLabelList });
      const binding = getBinding(findRemoveButton().element, 'gl-modal');
      expect(binding.value).toBe(modalID);
    });

    it('has the correct ID on the modal', () => {
      createComponent({ canAdminList: true, activeId: listId, list: mockLabelList });
      expect(findModal().props('modalId')).toBe(modalID);
    });
  });
});
