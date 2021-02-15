/* global List */
/* global ListIssue */
import MockAdapter from 'axios-mock-adapter';
import Sortable from 'sortablejs';
import Vue from 'vue';
import BoardList from '~/boards/components/board_list_deprecated.vue';
import '~/boards/models/issue';
import '~/boards/models/list';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';
import axios from '~/lib/utils/axios_utils';
import { listObj, boardsMockInterceptor } from './mock_data';

window.Sortable = Sortable;

export default function createComponent({
  done,
  listIssueProps = {},
  componentProps = {},
  listProps = {},
}) {
  const el = document.createElement('div');

  document.body.appendChild(el);
  const mock = new MockAdapter(axios);
  mock.onAny().reply(boardsMockInterceptor);
  boardsStore.create();

  const BoardListComp = Vue.extend(BoardList);
  const list = new List({ ...listObj, ...listProps });
  const issue = new ListIssue({
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [],
    assignees: [],
    ...listIssueProps,
  });
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesSize')) {
    list.issuesSize = 1;
  }
  list.issues.push(issue);

  const component = new BoardListComp({
    el,
    store,
    propsData: {
      disabled: false,
      list,
      issues: list.issues,
      loading: false,
      ...componentProps,
    },
    provide: {
      groupId: null,
      rootPath: '/',
    },
  }).$mount();

  Vue.nextTick(() => {
    done();
  });

  return { component, mock };
}
