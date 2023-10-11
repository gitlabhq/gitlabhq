import { generateRefDestinationPath } from '~/pages/projects/find_file/ref_switcher/ref_switcher_utils';
import setWindowLocation from 'helpers/set_window_location_helper';

const projectRootPath = 'root/Project1';
const selectedRef = 'feature/test';

describe('generateRefDestinationPath', () => {
  it.each`
    currentPath                                                                             | result
    ${`${projectRootPath}/-/find_file/flightjs/Flight`}                                     | ${`http://test.host/${projectRootPath}/-/find_file/${selectedRef}`}
    ${`${projectRootPath}/-/find_file/test/test1?test=something`}                           | ${`http://test.host/${projectRootPath}/-/find_file/${selectedRef}?test=something`}
    ${`${projectRootPath}/-/find_file/simpletest?test=something&test=it`}                   | ${`http://test.host/${projectRootPath}/-/find_file/${selectedRef}?test=something&test=it`}
    ${`${projectRootPath}/-/find_file/some_random_char?test=something&test[]=it&test[]=is`} | ${`http://test.host/${projectRootPath}/-/find_file/${selectedRef}?test=something&test%5B%5D=it&test%5B%5D=is`}
  `('generates the correct destination path for  $currentPath', ({ currentPath, result }) => {
    setWindowLocation(currentPath);
    expect(generateRefDestinationPath(selectedRef, '/-/find_file')).toBe(result);
  });

  it("returns original url if it's missing selectedRef param", () => {
    setWindowLocation(`${projectRootPath}/-/find_file/flightjs/Flight`);
    expect(generateRefDestinationPath(undefined, '/-/find_file')).toBe(
      `http://test.host/${projectRootPath}/-/find_file/flightjs/Flight`,
    );
  });

  it("returns original url if it's missing namespace param", () => {
    setWindowLocation(`${projectRootPath}/-/find_file/flightjs/Flight`);
    expect(generateRefDestinationPath(selectedRef, undefined)).toBe(
      `http://test.host/${projectRootPath}/-/find_file/flightjs/Flight`,
    );
  });

  it("returns original url if it's missing namespace and selectedRef param", () => {
    setWindowLocation(`${projectRootPath}/-/find_file/flightjs/Flight`);
    expect(generateRefDestinationPath(undefined, undefined)).toBe(
      `http://test.host/${projectRootPath}/-/find_file/flightjs/Flight`,
    );
  });

  it('removes ref_type from the destination url if ref is neither a branch or tag', () => {
    setWindowLocation(`${projectRootPath}/-/find_file/somebranch?ref_type=heads`);
    expect(generateRefDestinationPath('8e90e533', '/-/find_file')).toBe(
      `http://test.host/${projectRootPath}/-/find_file/8e90e533`,
    );
  });
});
