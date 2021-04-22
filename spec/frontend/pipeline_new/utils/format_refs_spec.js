import { BRANCH_REF_TYPE, TAG_REF_TYPE } from '~/pipeline_new/constants';
import formatRefs from '~/pipeline_new/utils/format_refs';
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
