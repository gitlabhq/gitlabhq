/* global List */

import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import boardNewIssue from '~/boards/components/board_new_issue_deprecated.vue';
import boardsStore from '~/boards/stores/boards_store';
import axios from '~/lib/utils/axios_utils';

import '~/boards/models/list';
import { listObj, boardsMockInterceptor } from './mock_data';

Vue.use(Vuex);

describe('Issue boards new issue form', () => {
  let wrapper;
  let vm;
  let list;
  let mock;
  let newIssueMock;
  const promiseReturn = {
    data: {
      iid: 100,
    },
  };

  const submitIssue = () => {
    const dummySubmitEvent = {
      preventDefault() {},
    };
    wrapper.vm.$refs.submitButton = wrapper.find({ ref: 'submitButton' });
    return wrapper.vm.submit(dummySubmitEvent);
  };

  beforeEach(() => {
    const BoardNewIssueComp = Vue.extend(boardNewIssue);

    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);

    boardsStore.create();

    list = new List(listObj);

    newIssueMock = Promise.resolve(promiseReturn);
    jest.spyOn(list, 'newIssue').mockImplementation(() => newIssueMock);

    const store = new Vuex.Store({
      getters: { isGroupBoard: () => false },
    });

    wrapper = mount(BoardNewIssueComp, {
      propsData: {
        disabled: false,
        list,
      },
      store,
      provide: {
        groupId: null,
      },
    });

    vm = wrapper.vm;

    return Vue.nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  it('calls submit if submit button is clicked', () => {
    jest.spyOn(wrapper.vm, 'submit').mockImplementation();
    vm.title = 'Testing Title';

    return Vue.nextTick()
      .then(submitIssue)
      .then(() => {
        expect(wrapper.vm.submit).toHaveBeenCalled();
      });
  });

  it('disables submit button if title is empty', () => {
    expect(wrapper.find({ ref: 'submitButton' }).props().disabled).toBe(true);
  });

  it('enables submit button if title is not empty', () => {
    wrapper.setData({ title: 'Testing Title' });

    return Vue.nextTick().then(() => {
      expect(wrapper.find({ ref: 'input' }).element.value).toBe('Testing Title');
      expect(wrapper.find({ ref: 'submitButton' }).props().disabled).toBe(false);
    });
  });

  it('clears title after clicking cancel', () => {
    wrapper.find({ ref: 'cancelButton' }).trigger('click');

    return Vue.nextTick().then(() => {
      expect(vm.title).toBe('');
    });
  });

  it('does not create new issue if title is empty', () => {
    return submitIssue().then(() => {
      expect(list.newIssue).not.toHaveBeenCalled();
    });
  });

  describe('submit success', () => {
    it('creates new issue', () => {
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(list.newIssue).toHaveBeenCalled();
        });
    });

    it('enables button after submit', () => {
      jest.spyOn(wrapper.vm, 'submit').mockImplementation();
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(wrapper.vm.$refs.submitButton.props().disabled).toBe(false);
        });
    });

    it('clears title after submit', () => {
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.title).toBe('');
        });
    });

    it('sets detail issue after submit', () => {
      expect(boardsStore.detail.issue.title).toBe(undefined);
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.issue.title).toBe('create issue');
        });
    });

    it('sets detail list after submit', () => {
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.id).toBe(list.id);
        });
    });

    it('sets detail weight after submit', () => {
      boardsStore.weightFeatureAvailable = true;
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.weight).toBe(list.weight);
        });
    });

    it('does not set detail weight after submit', () => {
      boardsStore.weightFeatureAvailable = false;
      wrapper.setData({ title: 'create issue' });

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.weight).toBe(list.weight);
        });
    });
  });

  describe('submit error', () => {
    beforeEach(() => {
      newIssueMock = Promise.reject(new Error('My hovercraft is full of eels!'));
      vm.title = 'error';
    });

    it('removes issue', () => {
      const lengthBefore = list.issues.length;
      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(list.issues.length).toBe(lengthBefore);
        });
    });

    it('shows error', () => {
      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.error).toBe(true);
        });
    });
  });
});
