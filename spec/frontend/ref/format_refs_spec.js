import { formatListBoxItems, formatErrors } from '~/ref/format_refs';
import { DEFAULT_I18N } from '~/ref/constants';
import {
  MOCK_BRANCHES,
  MOCK_COMMITS,
  MOCK_ERROR,
  MOCK_TAGS,
  FORMATTED_BRANCHES,
  FORMATTED_TAGS,
  FORMATTED_COMMITS,
} from './mock_data';

describe('formatListBoxItems', () => {
  it.each`
    branches         | tags         | commits         | expectedResult
    ${MOCK_BRANCHES} | ${MOCK_TAGS} | ${MOCK_COMMITS} | ${[FORMATTED_BRANCHES, FORMATTED_TAGS, FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${[]}        | ${MOCK_COMMITS} | ${[FORMATTED_BRANCHES, FORMATTED_COMMITS]}
    ${[]}            | ${[]}        | ${MOCK_COMMITS} | ${[FORMATTED_COMMITS]}
    ${undefined}     | ${undefined} | ${MOCK_COMMITS} | ${[FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${undefined} | ${null}         | ${[FORMATTED_BRANCHES]}
  `('should correctly format listbox items', ({ branches, tags, commits, expectedResult }) => {
    expect(formatListBoxItems(branches, tags, commits)).toStrictEqual(expectedResult);
  });

  it('should sort the default branch to the top', () => {
    const mockBranchesUnsorted = [
      { name: 'feature', default: false },
      { name: 'develop', default: false },
      { name: 'main', default: true },
      { name: 'bugfix', default: false },
    ];

    const sortedOptions = formatListBoxItems(mockBranchesUnsorted)[0].options;

    // The first item should be the default branch
    expect(sortedOptions[0].text).toBe('main');

    // Verify order is preserved among non-default items
    expect(sortedOptions[1].text).toBe('feature');
    expect(sortedOptions[2].text).toBe('develop');
    expect(sortedOptions[3].text).toBe('bugfix');
  });
});

describe('formatErrors', () => {
  const { branchesErrorMessage, tagsErrorMessage, commitsErrorMessage } = DEFAULT_I18N;
  it.each`
    branches      | tags          | commits       | expectedResult
    ${MOCK_ERROR} | ${MOCK_ERROR} | ${MOCK_ERROR} | ${[branchesErrorMessage, tagsErrorMessage, commitsErrorMessage]}
    ${MOCK_ERROR} | ${[]}         | ${MOCK_ERROR} | ${[branchesErrorMessage, commitsErrorMessage]}
    ${[]}         | ${[]}         | ${MOCK_ERROR} | ${[commitsErrorMessage]}
    ${undefined}  | ${undefined}  | ${MOCK_ERROR} | ${[commitsErrorMessage]}
    ${MOCK_ERROR} | ${undefined}  | ${null}       | ${[branchesErrorMessage]}
  `('should correctly format listbox errors', ({ branches, tags, commits, expectedResult }) => {
    expect(formatErrors(branches, tags, commits)).toEqual(expectedResult);
  });
});
