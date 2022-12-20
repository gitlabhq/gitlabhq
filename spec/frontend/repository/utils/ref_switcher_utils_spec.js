import { generateRefDestinationPath } from '~/repository/utils/ref_switcher_utils';
import setWindowLocation from 'helpers/set_window_location_helper';

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
  `('generates the correct destination path for  $currentPath', ({ currentPath, result }) => {
    setWindowLocation(currentPath);
    expect(generateRefDestinationPath(projectRootPath, selectedRef)).toBe(result);
  });
});
