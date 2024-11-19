import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'spec/test_constants';
import { refWithSpecialCharMock, encodedRefWithSpecialCharMock } from '../mock_data';

const projectRootPath = 'root/Project1';
const currentRef = 'main';
const selectedRef = 'feature';

describe('generateRefDestinationPath', () => {
  it.each`
    currentPath                                                         | result
    ${projectRootPath}                                                  | ${`${projectRootPath}/-/tree/${selectedRef}`}
    ${`${projectRootPath}/-/tree/${currentRef}/dir1`}                   | ${`${projectRootPath}/-/tree/${selectedRef}/dir1`}
    ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2`}              | ${`${projectRootPath}/-/tree/${selectedRef}/dir1/dir2`}
    ${`${projectRootPath}/-/blob/${currentRef}/test.js`}                | ${`${projectRootPath}/-/blob/${selectedRef}/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/test.js`}           | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js`}      | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/dir2/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/dir2/test.js#L123`}
  `('generates the correct destination path for $currentPath', ({ currentPath, result }) => {
    setWindowLocation(currentPath);
    expect(generateRefDestinationPath(projectRootPath, currentRef, selectedRef)).toBe(
      `${TEST_HOST}/${result}`,
    );
  });

  describe('when using symbolic ref names', () => {
    it.each`
      currentPath                                                         | nextRef                                             | result
      ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${'someHash'}                                       | ${`${projectRootPath}/-/blob/someHash/dir1/dir2/test.js#L123`}
      ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/heads/prefixedByUseSymbolicRefNames'}       | ${`${projectRootPath}/-/blob/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=heads#L123`}
      ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/tags/prefixedByUseSymbolicRefNames'}        | ${`${projectRootPath}/-/blob/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=tags#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/heads/prefixedByUseSymbolicRefNames'}       | ${`${projectRootPath}/-/tree/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=heads#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/tags/prefixedByUseSymbolicRefNames'}        | ${`${projectRootPath}/-/tree/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=tags#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/heads/refs/heads/branchNameContainsPrefix'} | ${`${projectRootPath}/-/tree/refs/heads/branchNameContainsPrefix/dir1/dir2/test.js?ref_type=heads#L123`}
      ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${'branch%percent'}                                 | ${`${projectRootPath}/-/blob/branch%25percent/dir1/dir2/test.js#L123`}
    `(
      'generates the correct destination path for $currentPath with ref type when it can be extracted',
      ({ currentPath, result, nextRef }) => {
        setWindowLocation(currentPath);
        expect(generateRefDestinationPath(projectRootPath, currentRef, nextRef)).toBe(
          `${TEST_HOST}/${result}`,
        );
      },
    );
  });

  it('encodes the selected ref', () => {
    const result = `${projectRootPath}/-/tree/${encodedRefWithSpecialCharMock}`;

    expect(generateRefDestinationPath(projectRootPath, currentRef, refWithSpecialCharMock)).toBe(
      `${TEST_HOST}/${result}`,
    );
  });
});
