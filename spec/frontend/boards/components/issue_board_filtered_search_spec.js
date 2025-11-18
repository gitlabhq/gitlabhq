import { orderBy } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from 'ee_else_ce/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('ee_else_ce/boards/issue_board_filters');

describe('IssueBoardFilter', () => {
  let wrapper;

  const findBoardsFilteredSearch = () => wrapper.findComponent(BoardFilteredSearch);

  const createComponent = ({ isSignedIn = false, workItemTasksOnBoardsEnabled = false } = {}) => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        filters: {},
      },
      provide: {
        isSignedIn,
        releasesFetchPath: '/releases',
        fullPath: 'gitlab-org',
        isGroupBoard: true,
        glFeatures: {
          workItemTasksOnBoards: workItemTasksOnBoardsEnabled,
        },
      },
      mocks: {
        $apollo: {},
      },
    });
  };

  let fetchLabelsSpy;
  beforeEach(() => {
    fetchLabelsSpy = jest.fn();

    issueBoardFilters.mockReturnValue({
      fetchLabels: fetchLabelsSpy,
    });
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(findBoardsFilteredSearch().exists()).toBe(true);
    });

    it('emits setFilters when setFilters is emitted', () => {
      findBoardsFilteredSearch().vm.$emit('setFilters');
      expect(wrapper.emitted('setFilters')).toHaveLength(1);
    });

    it.each`
      isSignedIn
      ${true}
      ${false}
    `(
      'passes the correct tokens to BoardFilteredSearch when user sign in is $isSignedIn',
      ({ isSignedIn }) => {
        createComponent({ isSignedIn });

        const tokens = mockTokens(fetchLabelsSpy, isSignedIn);

        expect(findBoardsFilteredSearch().props('tokens')).toEqual(orderBy(tokens, ['title']));
      },
    );

    it('does not have `Task` in work item type filter token when `workItemTasksOnBoards` is disabled', () => {
      createComponent({
        isSignedIn: true,
        workItemTasksOnBoardsEnabled: false,
      });

      const issuesToken = findBoardsFilteredSearch()
        .props('tokens')
        .find(({ type }) => type === 'type');

      expect(issuesToken.options).toHaveLength(2);
      expect(issuesToken.options).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ title: 'Incident' }),
          expect.objectContaining({ title: 'Issue' }),
        ]),
      );
    });

    it('has `Task` in work item type filter token when `workItemTasksOnBoards` is enabled', () => {
      createComponent({
        isSignedIn: true,
        workItemTasksOnBoardsEnabled: true,
      });

      const issuesToken = findBoardsFilteredSearch()
        .props('tokens')
        .find(({ type }) => type === 'type');

      expect(issuesToken.options).toHaveLength(3);
      expect(issuesToken.options).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ title: 'Incident' }),
          expect.objectContaining({ title: 'Issue' }),
          expect.objectContaining({ title: 'Task' }),
        ]),
      );
    });
  });
});
