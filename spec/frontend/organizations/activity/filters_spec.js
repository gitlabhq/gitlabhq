import { convertTokensToFilter } from '~/organizations/activity/filters';

import {
  MOCK_CONTRIBUTION_TYPE_VALUE,
  MOCK_SEARCH_TOKEN,
  MOCK_EMPTY_CONTRIBUTION_TYPE,
  MOCK_SELECTED_CONTRIBUTION_TYPE,
} from './mock_data';

describe('Organizations Activity Filters', () => {
  describe('convertTokensToFilter', () => {
    it.each`
      description                                   | tokens                                                  | result
      ${'no tokens'}                                | ${[]}                                                   | ${null}
      ${'only search token'}                        | ${[MOCK_SEARCH_TOKEN]}                                  | ${null}
      ${'empty contribution type token'}            | ${[MOCK_EMPTY_CONTRIBUTION_TYPE]}                       | ${undefined}
      ${'valid contribution type token'}            | ${[MOCK_SELECTED_CONTRIBUTION_TYPE]}                    | ${MOCK_CONTRIBUTION_TYPE_VALUE.data}
      ${'search and empty contribution type token'} | ${[MOCK_SEARCH_TOKEN, MOCK_EMPTY_CONTRIBUTION_TYPE]}    | ${undefined}
      ${'search and valid contribution type token'} | ${[MOCK_SEARCH_TOKEN, MOCK_SELECTED_CONTRIBUTION_TYPE]} | ${MOCK_CONTRIBUTION_TYPE_VALUE.data}
    `('returns $result with $description', ({ tokens, result }) => {
      expect(convertTokensToFilter(tokens)).toBe(result);
    });
  });
});
