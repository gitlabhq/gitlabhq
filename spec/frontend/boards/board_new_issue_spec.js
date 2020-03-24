/* global List */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import boardNewIssue from '~/boards/components/board_new_issue.vue';
import boardsStore from '~/boards/stores/boards_store';

import '~/boards/models/list';
import { listObj, boardsMockInterceptor } from './mock_data';

describe('Issue boards new issue form', () => {
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
    vm.$refs.submitButton = vm.$el.querySelector('.btn-success');
    return vm.submit(dummySubmitEvent);
  };

  beforeEach(() => {
    setFixtures('<div class="test-container"></div>');

    const BoardNewIssueComp = Vue.extend(boardNewIssue);

    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);

    boardsStore.create();

    list = new List(listObj);

    newIssueMock = Promise.resolve(promiseReturn);
    jest.spyOn(list, 'newIssue').mockImplementation(() => newIssueMock);

    vm = new BoardNewIssueComp({
      propsData: {
        list,
      },
    }).$mount(document.querySelector('.test-container'));

    return Vue.nextTick();
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  it('calls submit if submit button is clicked', () => {
    jest.spyOn(vm, 'submit').mockImplementation(e => e.preventDefault());
    vm.title = 'Testing Title';

    return Vue.nextTick().then(() => {
      vm.$el.querySelector('.btn-success').click();

      expect(vm.submit.mock.calls.length).toBe(1);
    });
  });

  it('disables submit button if title is empty', () => {
    expect(vm.$el.querySelector('.btn-success').disabled).toBe(true);
  });

  it('enables submit button if title is not empty', () => {
    vm.title = 'Testing Title';

    return Vue.nextTick().then(() => {
      expect(vm.$el.querySelector('.form-control').value).toBe('Testing Title');
      expect(vm.$el.querySelector('.btn-success').disabled).not.toBe(true);
    });
  });

  it('clears title after clicking cancel', () => {
    vm.$el.querySelector('.btn-default').click();

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
      vm.title = 'submit title';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(list.newIssue).toHaveBeenCalled();
        });
    });

    it('enables button after submit', () => {
      vm.title = 'submit issue';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.$el.querySelector('.btn-success').disabled).toBe(false);
        });
    });

    it('clears title after submit', () => {
      vm.title = 'submit issue';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.title).toBe('');
        });
    });

    it('sets detail issue after submit', () => {
      expect(boardsStore.detail.issue.title).toBe(undefined);
      vm.title = 'submit issue';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.issue.title).toBe('submit issue');
        });
    });

    it('sets detail list after submit', () => {
      vm.title = 'submit issue';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.id).toBe(list.id);
        });
    });

    it('sets detail weight after submit', () => {
      boardsStore.weightFeatureAvailable = true;
      vm.title = 'submit issue';

      return Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.weight).toBe(list.weight);
        });
    });

    it('does not set detail weight after submit', () => {
      boardsStore.weightFeatureAvailable = false;
      vm.title = 'submit issue';

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
