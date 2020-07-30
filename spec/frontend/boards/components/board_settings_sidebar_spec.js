import '~/boards/models/list';
import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlDrawer, GlLabel, GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import boardsStore from '~/boards/stores/boards_store';
import sidebarEventHub from '~/sidebar/event_hub';
import { inactiveId } from '~/boards/constants';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('BoardSettingsSidebar', () => {
  let wrapper;
  let mock;
  let storeActions;
  const labelTitle = 'test';
  const labelColor = '#FFFF';
  const listId = 1;

  const createComponent = (state = { activeId: inactiveId }, actions = {}) => {
    storeActions = actions;

    const store = new Vuex.Store({
      state,
      actions: storeActions,
    });

    wrapper = shallowMount(BoardSettingsSidebar, {
      store,
      localVue,
    });
  };
  const findLabel = () => wrapper.find(GlLabel);
  const findDrawer = () => wrapper.find(GlDrawer);

  beforeEach(() => {
    boardsStore.create();
  });

  afterEach(() => {
    jest.restoreAllMocks();
    wrapper.destroy();
  });

  it('finds a GlDrawer component', () => {
    createComponent();

    expect(findDrawer().exists()).toBe(true);
  });

  describe('on close', () => {
    it('calls closeSidebar', async () => {
      const spy = jest.fn();
      createComponent({ activeId: inactiveId }, { setActiveId: spy });

      findDrawer().vm.$emit('close');

      await wrapper.vm.$nextTick();

      expect(storeActions.setActiveId).toHaveBeenCalledWith(
        expect.anything(),
        inactiveId,
        undefined,
      );
    });

    it('calls closeSidebar on sidebar.closeAll event', async () => {
      createComponent({ activeId: inactiveId }, { setActiveId: jest.fn() });

      sidebarEventHub.$emit('sidebar.closeAll');

      await wrapper.vm.$nextTick();

      expect(storeActions.setActiveId).toHaveBeenCalledWith(
        expect.anything(),
        inactiveId,
        undefined,
      );
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
    });

    afterEach(() => {
      boardsStore.removeList(listId);
    });

    it('renders GlDrawer with open false', () => {
      createComponent({ activeId: 1 });

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

      createComponent({ activeId: listId });
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

      createComponent({ activeId: inactiveId });
    });

    afterEach(() => {
      mock.restore();
    });

    it('does not render GlLabel', () => {
      expect(findLabel().exists()).toBe(false);
    });
  });

  describe('when activeList is present', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      boardsStore.removeList(listId);
    });

    describe('when list type is "milestone"', () => {
      beforeEach(() => {
        boardsStore.addList({
          id: 1,
          milestone: {
            webUrl: 'https://gitlab.com/h5bp/html5-boilerplate/-/milestones/1',
            title: 'Backlog',
          },
          max_issue_count: 1,
          list_type: 'milestone',
        });
      });

      afterEach(() => {
        boardsStore.removeList(1, 'milestone');
        wrapper.destroy();
      });

      it('renders the correct milestone text', () => {
        createComponent({ activeId: 1 });

        expect(wrapper.find('.js-milestone').text()).toBe('Backlog');
      });

      it('renders the correct list type text', () => {
        createComponent({ activeId: 1 });

        expect(wrapper.find('.js-list-label').text()).toBe('Milestone');
      });
    });

    describe('when list type is "assignee"', () => {
      beforeEach(() => {
        boardsStore.addList({
          id: 1,
          user: { username: 'root', avatar: '', name: 'Test', webUrl: 'https://gitlab.com/root' },
          max_issue_count: 1,
          list_type: 'assignee',
        });
      });

      afterEach(() => {
        boardsStore.removeList(1, 'assignee');
        wrapper.destroy();
      });

      it('renders gl-avatar-link with correct href', () => {
        createComponent({ activeId: 1 });

        expect(wrapper.find(GlAvatarLink).exists()).toBe(true);
        expect(wrapper.find(GlAvatarLink).attributes('href')).toBe('https://gitlab.com/root');
      });

      it('renders gl-avatar-labeled with "root" as username and name as "Test"', () => {
        createComponent({ activeId: 1 });

        expect(wrapper.find(GlAvatarLabeled).exists()).toBe(true);
        expect(wrapper.find(GlAvatarLabeled).attributes('label')).toBe('Test');
        expect(wrapper.find(GlAvatarLabeled).attributes('sublabel')).toBe('@root');
      });

      it('renders the correct list type text', () => {
        createComponent({ activeId: 1 });

        expect(wrapper.find('.js-list-label').text()).toBe('Assignee');
      });
    });
  });
});
