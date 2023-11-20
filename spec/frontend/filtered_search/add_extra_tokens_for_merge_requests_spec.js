import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import { createFilteredSearchTokenKeys } from '~/filtered_search/issuable_filtered_search_token_keys';

describe('app/assets/javascripts/pages/dashboard/merge_requests/index.js', () => {
  let IssuableFilteredSearchTokenKeys;

  beforeEach(() => {
    IssuableFilteredSearchTokenKeys = createFilteredSearchTokenKeys();
    window.gon = {
      ...window.gon,
      features: {
        mrApprovedFilter: true,
      },
    };
  });

  describe.each(['Branch', 'Environment'])('when $filter is disabled', (filter) => {
    beforeEach(() => {
      addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys, {
        [`disable${filter}Filter`]: true,
      });
    });

    it('excludes the filter', () => {
      expect(IssuableFilteredSearchTokenKeys.tokenKeys).not.toContainEqual(
        expect.objectContaining({ tag: filter.toLowerCase() }),
      );
    });
  });
});
