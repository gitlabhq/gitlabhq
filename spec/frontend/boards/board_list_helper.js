import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import BoardCard from '~/boards/components/board_card.vue';
import BoardList from '~/boards/components/board_list.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import { mockList, boardListQueryResponse } from './mock_data';

export default function createComponent({
  componentProps = {},
  listProps = {},
  apolloQueryHandlers = [],
  apolloResolvers = {},
  provide = {},
  data = {},
  stubs = {
    BoardNewIssue,
    BoardNewItem,
    BoardCard,
  },
  mountOptions = {},
  issuesCount = undefined,
  totalIssueWeight = undefined,
} = {}) {
  Vue.use(VueApollo);

  const queryVariables = totalIssueWeight !== undefined ? { totalIssueWeight } : { issuesCount };

  const fakeApollo = createMockApollo(
    [
      [listQuery, jest.fn().mockResolvedValue(boardListQueryResponse(queryVariables))],
      ...apolloQueryHandlers,
    ],
    apolloResolvers,
  );

  const list = {
    ...mockList,
    ...listProps,
  };

  if (
    !Object.prototype.hasOwnProperty.call(listProps, 'issuesCount') &&
    totalIssueWeight === undefined
  ) {
    list.issuesCount = 1;
  }

  if (
    !Object.prototype.hasOwnProperty.call(listProps, 'totalIssueWeight') &&
    issuesCount === undefined
  ) {
    list.totalIssueWeight = 0;
  }

  const component = shallowMount(BoardList, {
    apolloProvider: fakeApollo,
    propsData: {
      list,
      canAdminList: true,
      boardId: 'gid://gitlab/Board/1',
      filterParams: {},
      columnIndex: 1,
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
      isGroupBoard: true,
      isProjectBoard: false,
      disabled: false,
      boardType: 'group',
      issuableType: 'issue',
      ...provide,
    },
    stubs,
    ...mountOptions,
    data() {
      return {
        ...data,
      };
    },
  });

  return component;
}
