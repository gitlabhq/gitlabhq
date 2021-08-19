import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('~/boards/issue_board_filters');

describe('IssueBoardFilter', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      props: { fullPath: '', boardType: '' },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    let fetchAuthorsSpy;
    let fetchLabelsSpy;
    beforeEach(() => {
      fetchAuthorsSpy = jest.fn();
      fetchLabelsSpy = jest.fn();

      issueBoardFilters.mockReturnValue({
        fetchAuthors: fetchAuthorsSpy,
        fetchLabels: fetchLabelsSpy,
      });

      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.find(BoardFilteredSearch).exists()).toBe(true);
    });

    it('passes the correct tokens to BoardFilteredSearch', () => {
      const tokens = mockTokens(fetchLabelsSpy, fetchAuthorsSpy, wrapper.vm.fetchMilestones);

      expect(wrapper.find(BoardFilteredSearch).props('tokens')).toEqual(tokens);
    });
  });
});
