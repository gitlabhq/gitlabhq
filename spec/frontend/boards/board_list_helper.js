import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';

import BoardCard from '~/boards/components/board_card.vue';
import BoardList from '~/boards/components/board_list.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import defaultState from '~/boards/stores/state';
import createMockApollo from 'helpers/mock_apollo_helper';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import {
  mockList,
  mockIssuesByListId,
  issues,
  mockGroupProjects,
  boardListQueryResponse,
} from './mock_data';

export default function createComponent({
  listIssueProps = {},
  componentProps = {},
  listProps = {},
  apolloQueryHandlers = [],
  actions = {},
  getters = {},
  provide = {},
  data = {},
  state = defaultState,
  stubs = {
    BoardNewIssue,
    BoardNewItem,
    BoardCard,
  },
  issuesCount,
} = {}) {
  Vue.use(VueApollo);
  Vue.use(Vuex);

  const fakeApollo = createMockApollo([
    [listQuery, jest.fn().mockResolvedValue(boardListQueryResponse(issuesCount))],
    ...apolloQueryHandlers,
  ]);

  const store = new Vuex.Store({
    state: {
      selectedProject: mockGroupProjects[0],
      boardItemsByListId: mockIssuesByListId,
      boardItems: issues,
      pageInfoByListId: {
        'gid://gitlab/List/1': { hasNextPage: true },
        'gid://gitlab/List/2': {},
      },
      listsFlags: {
        'gid://gitlab/List/1': {},
        'gid://gitlab/List/2': {},
      },
      selectedBoardItems: [],
      ...state,
    },
    getters: {
      isEpicBoard: () => false,
      ...getters,
    },
    actions,
  });

  const list = {
    ...mockList,
    ...listProps,
  };
  const issue = {
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    referencePath: 'gitlab-org/test-subgroup/gitlab-test#1',
    labels: [],
    assignees: [],
    ...listIssueProps,
  };
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesCount')) {
    list.issuesCount = 1;
  }

  const component = shallowMount(BoardList, {
    apolloProvider: fakeApollo,
    store,
    propsData: {
      list,
      boardItems: [issue],
      canAdminList: true,
      boardId: 'gid://gitlab/Board/1',
      filterParams: {},
      ...componentProps,
    },
    provide: {
      groupId: null,
      rootPath: '/',
      fullPath: 'gitlab-org',
      boardId: '1',
      weightFeatureAvailable: false,
      boardWeight: null,
      canAdminList: true,
      isIssueBoard: true,
      isEpicBoard: false,
      isGroupBoard: false,
      isProjectBoard: true,
      disabled: false,
      boardType: 'group',
      issuableType: 'issue',
      isApolloBoard: false,
      ...provide,
    },
    stubs,
    data() {
      return {
        ...data,
      };
    },
  });

  return component;
}
