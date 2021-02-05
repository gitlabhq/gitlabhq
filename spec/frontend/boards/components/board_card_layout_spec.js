import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';

import defaultState from '~/boards/stores/state';
import BoardCardLayout from '~/boards/components/board_card_layout.vue';
import IssueCardInner from '~/boards/components/issue_card_inner.vue';
import { ISSUABLE } from '~/boards/constants';
import { mockLabelList, mockIssue } from '../mock_data';

describe('Board card layout', () => {
  let wrapper;
  let store;

  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createStore = ({ getters = {}, actions = {} } = {}) => {
    store = new Vuex.Store({
      state: defaultState,
      actions,
      getters,
    });
  };

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMount(BoardCardLayout, {
      localVue,
      stubs: {
        IssueCardInner,
      },
      store,
      propsData: {
        list: mockLabelList,
        issue: mockIssue,
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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

    it("calls 'setActiveId'", async () => {
      const setActiveId = jest.fn();
      createStore({
        actions: {
          setActiveId,
        },
      });
      mountComponent();

      wrapper.trigger('mouseup');
      await wrapper.vm.$nextTick();

      expect(setActiveId).toHaveBeenCalledTimes(1);
      expect(setActiveId).toHaveBeenCalledWith(expect.any(Object), {
        id: mockIssue.id,
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
        id: mockIssue.id,
        sidebarType: ISSUABLE,
      });
    });
  });
});
