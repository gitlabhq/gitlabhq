import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('~/boards/issue_board_filters');

describe('IssueBoardFilter', () => {
  let wrapper;

  const findBoardsFilteredSearch = () => wrapper.findComponent(BoardFilteredSearch);

  const createComponent = ({ epicFeatureAvailable = false } = {}) => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      propsData: { fullPath: 'gitlab-org', boardType: 'group' },
      provide: {
        epicFeatureAvailable,
      },
    });
  };

  let fetchAuthorsSpy;
  let fetchLabelsSpy;
  beforeEach(() => {
    fetchAuthorsSpy = jest.fn();
    fetchLabelsSpy = jest.fn();

    issueBoardFilters.mockReturnValue({
      fetchAuthors: fetchAuthorsSpy,
      fetchLabels: fetchLabelsSpy,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(findBoardsFilteredSearch().exists()).toBe(true);
    });

    it('passes the correct tokens to BoardFilteredSearch', () => {
      const tokens = mockTokens(fetchLabelsSpy, fetchAuthorsSpy, wrapper.vm.fetchMilestones);

      expect(findBoardsFilteredSearch().props('tokens')).toEqual(tokens);
    });
  });
});
