import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import IssuableContext from '~/issuable_context';
import AssigneeSelect from 'ee/boards/components/assignee_select.vue';
import { boardObj, mockBoardService } from 'spec/boards/mock_data';

let vm;

function selectedText() {
  return vm.$el.querySelector('.value').innerText.trim();
}

function activeDropdownItem(index) {
  const items = document.querySelectorAll('.is-active');
  if (!items[index]) return '';
  return items[index].innerText.trim();
}

const assignee = {
  id: 1,
  name: 'first assignee',
};

const assignee2 = {
  id: 2,
  name: 'second assignee',
};

describe('Assignee select component', () => {
  beforeEach((done) => {
    setFixtures('<div class="test-container"></div>');
    gl.boardService = mockBoardService();
    gl.issueBoards.BoardsStore.create();

    // eslint-disable-next-line no-new
    new IssuableContext();

    const Component = Vue.extend(AssigneeSelect);
    vm = new Component({
      propsData: {
        board: boardObj,
        assigneePath: '/test/issue-boards/assignees.json',
        canEdit: true,
        label: 'Assignee',
        selected: {},
        fieldName: 'assignee_id',
        anyUserText: 'Any assignee',
      },
    }).$mount('.test-container');

    setTimeout(done);
  });

  describe('canEdit', () => {
    it('hides Edit button', (done) => {
      vm.canEdit = false;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeFalsy();
        done();
      });
    });

    it('shows Edit button if true', (done) => {
      vm.canEdit = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeTruthy();
        done();
      });
    });
  });

  describe('selected value', () => {
    it('defaults to Any Assignee', () => {
      expect(selectedText()).toContain('Any assignee');
    });

    it('shows selected assignee', (done) => {
      vm.selected = assignee;
      Vue.nextTick(() => {
        expect(selectedText()).toContain('first assignee');
        done();
      });
    });

    describe('clicking dropdown items', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        mock.onGet('/autocomplete/users.json').reply(200, [
          assignee,
          assignee2,
        ]);
      });

      afterEach(() => {
        mock.restore();
      });

      it('sets assignee', (done) => {
        vm.$el.querySelector('.edit-link').click();

        setTimeout(() => {
          vm.$el.querySelectorAll('li a')[2].click();

          setTimeout(() => {
            expect(activeDropdownItem(0)).toEqual('second assignee');
            expect(vm.board.assignee).toEqual(assignee2);
            done();
          });
        });
      });
    });
  });
});
