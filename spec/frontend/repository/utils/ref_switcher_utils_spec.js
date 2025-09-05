import {
  generateRefDestinationPath,
  generateRouterParams,
} from '~/repository/utils/ref_switcher_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'spec/test_constants';
import { refWithSpecialCharMock, encodedRefWithSpecialCharMock } from '../mock_data';

const projectRootPath = 'root/Project1';

describe('generateRefDestinationPath', () => {
  const currentRef = 'main';
  const selectedRef = 'feature';

  it.each`
    currentPath                                                         | result
    ${projectRootPath}                                                  | ${`${projectRootPath}/-/tree/${selectedRef}`}
    ${`${projectRootPath}/-/tree/${currentRef}/dir1`}                   | ${`${projectRootPath}/-/tree/${selectedRef}/dir1`}
    ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2`}              | ${`${projectRootPath}/-/tree/${selectedRef}/dir1/dir2`}
    ${`${projectRootPath}/-/blob/${currentRef}/test.js`}                | ${`${projectRootPath}/-/blob/${selectedRef}/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/test.js`}           | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js`}      | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/dir2/test.js`}
    ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${`${projectRootPath}/-/blob/${selectedRef}/dir1/dir2/test.js#L123`}
    ${`${projectRootPath}/blob/${currentRef}/test.js`}                  | ${`${projectRootPath}/blob/${selectedRef}/test.js`}
    ${`${projectRootPath}/blob/${currentRef}/dir1/test.js`}             | ${`${projectRootPath}/blob/${selectedRef}/dir1/test.js`}
    ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js`}        | ${`${projectRootPath}/blob/${selectedRef}/dir1/dir2/test.js`}
    ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js#L123`}   | ${`${projectRootPath}/blob/${selectedRef}/dir1/dir2/test.js#L123`}
    ${`${projectRootPath}/-/commits/${currentRef}`}                     | ${`${projectRootPath}/-/commits/${selectedRef}`}
    ${`${projectRootPath}/-/commits/${currentRef}/test.js`}             | ${`${projectRootPath}/-/commits/${selectedRef}/test.js`}
    ${`${projectRootPath}/-/commits/${currentRef}/dir1/test.js`}        | ${`${projectRootPath}/-/commits/${selectedRef}/dir1/test.js`}
    ${`${projectRootPath}/-/commits/${currentRef}/dir1/dir2/test.js`}   | ${`${projectRootPath}/-/commits/${selectedRef}/dir1/dir2/test.js`}
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
      ${`${projectRootPath}/-/blob/${currentRef}/dir1/dir2/test.js#L123`} | ${'branch%percent'}                                 | ${`${projectRootPath}/-/blob/branch%25percent/dir1/dir2/test.js#L123`}
      ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js#L123`}   | ${'someHash'}                                       | ${`${projectRootPath}/blob/someHash/dir1/dir2/test.js#L123`}
      ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js#L123`}   | ${'refs/heads/prefixedByUseSymbolicRefNames'}       | ${`${projectRootPath}/blob/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=heads#L123`}
      ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js#L123`}   | ${'refs/tags/prefixedByUseSymbolicRefNames'}        | ${`${projectRootPath}/blob/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=tags#L123`}
      ${`${projectRootPath}/blob/${currentRef}/dir1/dir2/test.js#L123`}   | ${'branch%percent'}                                 | ${`${projectRootPath}/blob/branch%25percent/dir1/dir2/test.js#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/heads/prefixedByUseSymbolicRefNames'}       | ${`${projectRootPath}/-/tree/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=heads#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/tags/prefixedByUseSymbolicRefNames'}        | ${`${projectRootPath}/-/tree/prefixedByUseSymbolicRefNames/dir1/dir2/test.js?ref_type=tags#L123`}
      ${`${projectRootPath}/-/tree/${currentRef}/dir1/dir2/test.js#L123`} | ${'refs/heads/refs/heads/branchNameContainsPrefix'} | ${`${projectRootPath}/-/tree/refs/heads/branchNameContainsPrefix/dir1/dir2/test.js?ref_type=heads#L123`}
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

describe('generateRouterParams', () => {
  const mockRoute = {
    params: { path: 'src/components' },
    query: { search: 'test' },
  };

  it.each`
    selectedRef               | expectedPath                                          | expectedQuery
    ${'feature-branch'}       | ${'/feature-branch/src/components'}                   | ${{ search: 'test' }}
    ${'refs/heads/feature-branch'} | ${'/feature-branch/src/components'} | ${{
  search: 'test',
  ref_type: 'heads',
}}
    ${'refs/tags/v1.0.0'} | ${'/v1.0.0/src/components'} | ${{
  search: 'test',
  ref_type: 'tags',
}}
    ${refWithSpecialCharMock} | ${`/${encodedRefWithSpecialCharMock}/src/components`} | ${{ search: 'test' }}
  `(
    'with $selectedRef generates correct router params',
    ({ selectedRef, expectedPath, expectedQuery }) => {
      const result = generateRouterParams(selectedRef, mockRoute);

      expect(result).toEqual({
        path: expectedPath,
        query: expectedQuery,
      });
    },
  );

  it('handles route without path param', () => {
    const routeWithoutPath = { params: {}, query: { search: 'test' } };
    const result = generateRouterParams('main', routeWithoutPath);

    expect(result).toEqual({
      path: '/main/',
      query: { search: 'test' },
    });
  });

  it('removes ref_type from query when switching to non-symbolic ref', () => {
    const routeWithRefType = {
      params: { path: 'src' },
      query: { ref_type: 'heads', search: 'test' },
    };
    const result = generateRouterParams('main', routeWithRefType);

    expect(result).toEqual({
      path: '/main/src',
      query: { search: 'test' },
    });
  });

  it('preserves existing query params when adding ref_type', () => {
    const routeWithMultipleParams = {
      params: { path: 'src' },
      query: { search: 'test', sort: 'name', filter: 'js' },
    };
    const result = generateRouterParams('refs/heads/feature', routeWithMultipleParams);

    expect(result).toEqual({
      path: '/feature/src',
      query: { search: 'test', sort: 'name', filter: 'js', ref_type: 'heads' },
    });
  });
});
