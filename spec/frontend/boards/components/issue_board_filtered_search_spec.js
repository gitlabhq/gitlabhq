import { orderBy } from 'lodash-es';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from 'ee_else_ce/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('ee_else_ce/boards/issue_board_filters');

Vue.use(VueApollo);

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
      apolloProvider: createMockApollo([]),
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

    it('emits set-filters when set-filters is emitted', () => {
      findBoardsFilteredSearch().vm.$emit('set-filters');
      expect(wrapper.emitted('set-filters')).toHaveLength(1);
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
  });
});
