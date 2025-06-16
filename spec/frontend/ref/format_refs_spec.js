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
  const FORMATTED_SELECTED = {
    text: DEFAULT_I18N.selected,
    options: [{ text: 'selected', value: 'selected', default: undefined, protected: undefined }],
  };
  const selected = { name: 'selected', value: 'selected' };

  it.each`
    branches         | tags         | commits         | selectedRef  | expectedResult
    ${MOCK_BRANCHES} | ${MOCK_TAGS} | ${MOCK_COMMITS} | ${undefined} | ${[FORMATTED_BRANCHES, FORMATTED_TAGS, FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${MOCK_TAGS} | ${MOCK_COMMITS} | ${selected}  | ${[FORMATTED_SELECTED, FORMATTED_BRANCHES, FORMATTED_TAGS, FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${[]}        | ${MOCK_COMMITS} | ${undefined} | ${[FORMATTED_BRANCHES, FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${[]}        | ${MOCK_COMMITS} | ${selected}  | ${[FORMATTED_SELECTED, FORMATTED_BRANCHES, FORMATTED_COMMITS]}
    ${[]}            | ${[]}        | ${MOCK_COMMITS} | ${undefined} | ${[FORMATTED_COMMITS]}
    ${[]}            | ${[]}        | ${MOCK_COMMITS} | ${selected}  | ${[FORMATTED_SELECTED, FORMATTED_COMMITS]}
    ${undefined}     | ${undefined} | ${MOCK_COMMITS} | ${undefined} | ${[FORMATTED_COMMITS]}
    ${undefined}     | ${undefined} | ${MOCK_COMMITS} | ${selected}  | ${[FORMATTED_SELECTED, FORMATTED_COMMITS]}
    ${MOCK_BRANCHES} | ${undefined} | ${null}         | ${undefined} | ${[FORMATTED_BRANCHES]}
    ${MOCK_BRANCHES} | ${undefined} | ${null}         | ${selected}  | ${[FORMATTED_SELECTED, FORMATTED_BRANCHES]}
  `(
    'should correctly format listbox items',
    ({ branches, tags, commits, selectedRef, expectedResult }) => {
      expect(formatListBoxItems({ branches, tags, commits, selectedRef })).toStrictEqual(
        expectedResult,
      );
    },
  );

  it('filters selectedRef from other sections', () => {
    const branches = [
      { name: 'main', value: 'main' },
      { name: 'feature', value: 'feature' },
      { name: 'bugfix', value: 'bugfix' },
    ];
    const branchSelectedRef = branches[0]; // Assume first branch is selected
    const result = formatListBoxItems({
      branches,
      tags: MOCK_TAGS,
      commits: MOCK_COMMITS,
      selectedRef: branchSelectedRef,
    });

    const selectedSection = result.find((section) => section.text === DEFAULT_I18N.selected);
    const branchesSection = result.find((section) => section.text === DEFAULT_I18N.branches);

    expect(selectedSection.options).toHaveLength(1);
    expect(branchesSection.options).toHaveLength(MOCK_BRANCHES.length - 1); // One less because selected is filtered out
  });

  it('should sort the default branch to the top', () => {
    const mockBranchesUnsorted = [
      { name: 'feature', default: false },
      { name: 'develop', default: false },
      { name: 'main', default: true },
      { name: 'bugfix', default: false },
    ];

    const sortedOptions = formatListBoxItems({ branches: mockBranchesUnsorted })[0].options;

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
