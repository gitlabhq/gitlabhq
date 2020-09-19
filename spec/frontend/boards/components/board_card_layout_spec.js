/* global List */
/* global ListLabel */

import { shallowMount } from '@vue/test-utils';

import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';

import '~/boards/models/label';
import '~/boards/models/assignee';
import '~/boards/models/list';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import BoardCardLayout from '~/boards/components/board_card_layout.vue';
import issueCardInner from '~/boards/components/issue_card_inner.vue';
import { listObj, boardsMockInterceptor, setMockEndpoints } from '../mock_data';

describe('Board card layout', () => {
  let wrapper;
  let mock;
  let list;

  // this particular mount component needs to be used after the root beforeEach because it depends on list being initialized
  const mountComponent = propsData => {
    wrapper = shallowMount(BoardCardLayout, {
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
      mountComponent();

      wrapper.trigger('mousedown');
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.showDetail).toBe(true);
    });

    it('sets showDetail to false on mousemove', async () => {
      mountComponent();
      wrapper.trigger('mousedown');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.showDetail).toBe(true);
      wrapper.trigger('mousemove');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.showDetail).toBe(false);
    });
  });
});
