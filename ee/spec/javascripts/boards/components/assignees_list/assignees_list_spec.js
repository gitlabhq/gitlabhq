import '~/boards/stores/boards_store';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AssigneesListComponent from 'ee/boards/components/assignees_list/';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockAssigneesList } from 'spec/boards/mock_data';
import { TEST_HOST } from 'spec/test_constants';

describe('AssigneesListComponent', () => {
  const dummyEndpoint = `${TEST_HOST}/users.json`;

  const createComponent = () =>
    mountComponent(AssigneesListComponent, {
      listAssigneesPath: dummyEndpoint,
    });

  let vm;
  let mock;

  gl.issueBoards.BoardsStore.create();
  gl.issueBoards.BoardsStore.state.assignees = [];

  beforeEach(() => {
    mock = new MockAdapter(axios);

    setFixtures('<div class="flash-container"></div>');
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.loading).toBe(true);
      expect(vm.store).toBe(gl.issueBoards.BoardsStore);
    });
  });

  describe('methods', () => {
    describe('loadAssignees', () => {
      it('calls axios.get and sets response to store.state.assignees', done => {
        mock.onGet(dummyEndpoint).reply(200, mockAssigneesList);
        gl.issueBoards.BoardsStore.state.assignees = [];

        vm
          .loadAssignees()
          .then(() => {
            expect(vm.loading).toBe(false);
            expect(vm.store.state.assignees.length).toBe(mockAssigneesList.length);
          })
          .then(done)
          .catch(done.fail);
      });

      it('does not call axios.get when store.state.assignees is not empty', done => {
        spyOn(axios, 'get');
        gl.issueBoards.BoardsStore.state.assignees = mockAssigneesList;

        vm
          .loadAssignees()
          .then(() => {
            expect(axios.get).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('calls axios.get and shows Flash error when request fails', done => {
        mock.onGet(dummyEndpoint).replyOnce(500, {});
        gl.issueBoards.BoardsStore.state.assignees = [];

        vm
          .loadAssignees()
          .then(() => {
            expect(vm.loading).toBe(false);
            expect(document.querySelector('.flash-text').innerText.trim()).toBe(
              'Something went wrong while fetching assignees list',
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('handleItemClick', () => {
      it('creates new list in a store instance', () => {
        spyOn(vm.store, 'new');
        const assignee = mockAssigneesList[0];

        expect(vm.store.findList('title', assignee.name)).not.toBeDefined();
        vm.handleItemClick(assignee);
        expect(vm.store.new).toHaveBeenCalledWith(jasmine.any(Object));
      });
    });
  });
});
