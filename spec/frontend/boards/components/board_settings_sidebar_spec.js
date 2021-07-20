import '~/boards/models/list';
import { GlDrawer, GlLabel } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { MountingPortal } from 'portal-vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import { inactiveId, LIST } from '~/boards/constants';
import { createStore } from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import sidebarEventHub from '~/sidebar/event_hub';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('BoardSettingsSidebar', () => {
  let wrapper;
  let mock;
  let store;
  const labelTitle = 'test';
  const labelColor = '#FFFF';
  const listId = 1;

  const findRemoveButton = () => wrapper.findByTestId('remove-list');

  const createComponent = ({ canAdminList = false } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardSettingsSidebar, {
        store,
        localVue,
        provide: {
          canAdminList,
        },
      }),
    );
  };
  const findLabel = () => wrapper.find(GlLabel);
  const findDrawer = () => wrapper.find(GlDrawer);

  beforeEach(() => {
    store = createStore();
    store.state.activeId = inactiveId;
    store.state.sidebarType = LIST;
    boardsStore.create();
  });

  afterEach(() => {
    jest.restoreAllMocks();
    wrapper.destroy();
  });

  it('finds a MountingPortal component', () => {
    createComponent();

    expect(wrapper.find(MountingPortal).props()).toMatchObject({
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

        await wrapper.vm.$nextTick();

        expect(wrapper.find(GlDrawer).exists()).toBe(false);
      });

      it('closes the sidebar when emitting the correct event', async () => {
        createComponent();

        sidebarEventHub.$emit('sidebar.closeAll');

        await wrapper.vm.$nextTick();

        expect(wrapper.find(GlDrawer).exists()).toBe(false);
      });
    });

    describe('when activeId is zero', () => {
      it('renders GlDrawer with open false', () => {
        createComponent();

        expect(findDrawer().props('open')).toBe(false);
      });
    });

    describe('when activeId is greater than zero', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);

        boardsStore.addList({
          id: listId,
          label: { title: labelTitle, color: labelColor },
          list_type: 'label',
        });
        store.state.activeId = 1;
        store.state.sidebarType = LIST;
      });

      afterEach(() => {
        boardsStore.removeList(listId);
      });

      it('renders GlDrawer with open false', () => {
        createComponent();

        expect(findDrawer().props('open')).toBe(true);
      });
    });

    describe('when activeId is in boardsStore', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);

        boardsStore.addList({
          id: listId,
          label: { title: labelTitle, color: labelColor },
          list_type: 'label',
        });

        store.state.activeId = listId;
        store.state.sidebarType = LIST;

        createComponent();
      });

      afterEach(() => {
        mock.restore();
      });

      it('renders label title', () => {
        expect(findLabel().props('title')).toBe(labelTitle);
      });

      it('renders label background color', () => {
        expect(findLabel().props('backgroundColor')).toBe(labelColor);
      });
    });

    describe('when activeId is not in boardsStore', () => {
      beforeEach(() => {
        mock = new MockAdapter(axios);

        boardsStore.addList({ id: listId, label: { title: labelTitle, color: labelColor } });

        store.state.activeId = inactiveId;

        createComponent();
      });

      afterEach(() => {
        mock.restore();
      });

      it('does not render GlLabel', () => {
        expect(findLabel().exists()).toBe(false);
      });
    });
  });

  describe('when sidebarType is not List', () => {
    beforeEach(() => {
      store.state.sidebarType = '';
      createComponent();
    });

    it('does not render GlDrawer', () => {
      expect(findDrawer().exists()).toBe(false);
    });
  });

  it('does not render "Remove list" when user cannot admin the boards list', () => {
    createComponent();

    expect(findRemoveButton().exists()).toBe(false);
  });

  describe('when user can admin the boards list', () => {
    beforeEach(() => {
      store.state.activeId = listId;
      store.state.sidebarType = LIST;

      boardsStore.addList({
        id: listId,
        label: { title: labelTitle, color: labelColor },
        list_type: 'label',
      });

      createComponent({ canAdminList: true });
    });

    it('renders "Remove list" button', () => {
      expect(findRemoveButton().exists()).toBe(true);
    });
  });
});
