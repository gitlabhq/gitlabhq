import { BRANCH_SUFFIX_COUNT } from '~/static_site_editor/constants';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';

import { username, branch as targetBranch } from '../mock_data';

describe('generateBranchName', () => {
  const timestamp = 12345678901234;

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockReturnValueOnce(timestamp);
  });

  it('generates a name that includes the username and target branch', () => {
    expect(generateBranchName(username, targetBranch)).toMatch(`${username}-${targetBranch}`);
  });

  it(`adds the first ${BRANCH_SUFFIX_COUNT} numbers of the current timestamp`, () => {
    expect(generateBranchName(username, targetBranch)).toMatch(
      timestamp.toString().substring(BRANCH_SUFFIX_COUNT),
    );
  });
});
