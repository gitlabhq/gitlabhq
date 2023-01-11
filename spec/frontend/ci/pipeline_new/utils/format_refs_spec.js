import { BRANCH_REF_TYPE, TAG_REF_TYPE } from '~/ci/pipeline_new/constants';
import {
  formatRefs,
  formatListBoxItems,
  searchByFullNameInListboxOptions,
} from '~/ci/pipeline_new/utils/format_refs';
import { mockBranchRefs, mockTagRefs } from '../mock_data';

describe('Format refs util', () => {
  it('formats branch ref correctly', () => {
    expect(formatRefs(mockBranchRefs, BRANCH_REF_TYPE)).toEqual([
      { fullName: 'refs/heads/main', shortName: 'main' },
      { fullName: 'refs/heads/dev', shortName: 'dev' },
      { fullName: 'refs/heads/release', shortName: 'release' },
    ]);
  });

  it('formats tag ref correctly', () => {
    expect(formatRefs(mockTagRefs, TAG_REF_TYPE)).toEqual([
      { fullName: 'refs/tags/1.0.0', shortName: '1.0.0' },
      { fullName: 'refs/tags/1.1.0', shortName: '1.1.0' },
      { fullName: 'refs/tags/1.2.0', shortName: '1.2.0' },
    ]);
  });
});

describe('formatListBoxItems', () => {
  it('formats branches and tags to listbox items correctly', () => {
    expect(formatListBoxItems(mockBranchRefs, mockTagRefs)).toEqual([
      {
        text: 'Branches',
        options: [
          { value: 'refs/heads/main', text: 'main' },
          { value: 'refs/heads/dev', text: 'dev' },
          { value: 'refs/heads/release', text: 'release' },
        ],
      },
      {
        text: 'Tags',
        options: [
          { value: 'refs/tags/1.0.0', text: '1.0.0' },
          { value: 'refs/tags/1.1.0', text: '1.1.0' },
          { value: 'refs/tags/1.2.0', text: '1.2.0' },
        ],
      },
    ]);

    expect(formatListBoxItems(mockBranchRefs, [])).toEqual([
      {
        text: 'Branches',
        options: [
          { value: 'refs/heads/main', text: 'main' },
          { value: 'refs/heads/dev', text: 'dev' },
          { value: 'refs/heads/release', text: 'release' },
        ],
      },
    ]);

    expect(formatListBoxItems([], mockTagRefs)).toEqual([
      {
        text: 'Tags',
        options: [
          { value: 'refs/tags/1.0.0', text: '1.0.0' },
          { value: 'refs/tags/1.1.0', text: '1.1.0' },
          { value: 'refs/tags/1.2.0', text: '1.2.0' },
        ],
      },
    ]);
  });
});

describe('searchByFullNameInListboxOptions', () => {
  const listbox = formatListBoxItems(mockBranchRefs, mockTagRefs);

  it.each`
    fullName             | expectedResult
    ${'refs/heads/main'} | ${{ fullName: 'refs/heads/main', shortName: 'main' }}
    ${'refs/tags/1.0.0'} | ${{ fullName: 'refs/tags/1.0.0', shortName: '1.0.0' }}
  `('should search item in listbox correctly', ({ fullName, expectedResult }) => {
    expect(searchByFullNameInListboxOptions(fullName, listbox)).toEqual(expectedResult);
  });
});
