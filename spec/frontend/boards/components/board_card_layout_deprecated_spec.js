/* global List */
/* global ListLabel */

import { createLocalVue, shallowMount } from '@vue/test-utils';

import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';

import '~/boards/models/label';
import '~/boards/models/assignee';
import '~/boards/models/list';
import BoardCardLayout from '~/boards/components/board_card_layout_deprecated.vue';
import issueCardInner from '~/boards/components/issue_card_inner_deprecated.vue';
import { ISSUABLE } from '~/boards/constants';
import boardsVuexStore from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import axios from '~/lib/utils/axios_utils';
import { listObj, boardsMockInterceptor, setMockEndpoints } from '../mock_data';

describe('Board card layout', () => {
  let wrapper;
  let mock;
  let list;
  let store;

  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createStore = ({ getters = {}, actions = {} } = {}) => {
    store = new Vuex.Store({
      ...boardsVuexStore,
      actions,
      getters,
    });
  };

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(BoardCardLayout, {
      localVue,
      stubs: {
        issueCardInner,
      },
      store,
      propsData: {
        list,
        issue: list.issues[0],
        disabled: false,
        index: 0,
        ...propsData,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
        ...provide,
      },
    });
  };

  const setupData = () => {
    list = new List(listObj);
    boardsStore.create();
    boardsStore.detail.issue = {};
    const label1 = new ListLabel({
      id: 3,
      title: 'testing 123',
      color: '#000cff',
      text_color: 'white',
      description: 'test',
    });
    return waitForPromises().then(() => {
      list.issues[0].labels.push(label1);
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);
    setMockEndpoints();
    return setupData();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    list = null;
    mock.restore();
  });

  describe('mouse events', () => {
    it('sets showDetail to true on mousedown', async () => {
      createStore();
      mountComponent();

      wrapper.trigger('mousedown');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showDetail).toBe(true);
    });

    it('sets showDetail to false on mousemove', async () => {
      createStore();
      mountComponent();
      wrapper.trigger('mousedown');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.showDetail).toBe(true);
      wrapper.trigger('mousemove');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.showDetail).toBe(false);
    });

    it("calls 'setActiveId' when 'graphqlBoardLists' feature flag is turned on", async () => {
      const setActiveId = jest.fn();
      createStore({
        actions: {
          setActiveId,
        },
      });
      mountComponent({
        provide: {
          glFeatures: { graphqlBoardLists: true },
        },
      });

      wrapper.trigger('mouseup');
      await wrapper.vm.$nextTick();

      expect(setActiveId).toHaveBeenCalledTimes(1);
      expect(setActiveId).toHaveBeenCalledWith(expect.any(Object), {
        id: list.issues[0].id,
        sidebarType: ISSUABLE,
      });
    });

    it("calls 'setActiveId' when epic swimlanes is active", async () => {
      const setActiveId = jest.fn();
      const isSwimlanesOn = () => true;
      createStore({
        getters: { isSwimlanesOn },
        actions: {
          setActiveId,
        },
      });
      mountComponent();

      wrapper.trigger('mouseup');
      await wrapper.vm.$nextTick();

      expect(setActiveId).toHaveBeenCalledTimes(1);
      expect(setActiveId).toHaveBeenCalledWith(expect.any(Object), {
        id: list.issues[0].id,
        sidebarType: ISSUABLE,
      });
    });
  });
});
