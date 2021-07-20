import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import { BoardType } from '~/boards/constants';
import issueBoardFilters from '~/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

describe('IssueBoardFilter', () => {
  let wrapper;

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      provide: { initialFilterParams },
      props: { fullPath: '', boardType: '' },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.find(BoardFilteredSearch).exists()).toBe(true);
    });

    it.each([[BoardType.group], [BoardType.project]])(
      'when boardType is %s we pass the correct tokens to BoardFilteredSearch',
      (boardType) => {
        const { fetchAuthors, fetchLabels } = issueBoardFilters({}, '', boardType);

        const tokens = mockTokens(fetchLabels, fetchAuthors);

        expect(wrapper.find(BoardFilteredSearch).props('tokens').toString()).toBe(
          tokens.toString(),
        );
      },
    );
  });
});
