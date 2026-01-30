// To run this spec locally first run `bundle exec rake gitlab:js:routes`

import { sharedPathHelperTests } from './shared';

const testCases = [
  {
    pathHelperName: 'editProjectPath',
    args: ['foo/bar/baz'],
    baseExpected: '/foo/bar/baz/edit',
  },
  {
    pathHelperName: 'editProjectPath',
    args: ['baz'],
    baseExpected: '/baz/edit',
  },
  {
    pathHelperName: 'editProjectPath',
    args: ['/baz'],
    baseExpected: '/baz/edit',
  },
  {
    pathHelperName: 'editProjectPath',
    args: [
      '/baz',
      { search: 'foo bar', page: '1', format: 'json', anchor: 'js-visibility-settings' },
    ],
    baseExpected: '/baz/edit.json?search=foo%20bar&page=1#js-visibility-settings',
  },
];

sharedPathHelperTests({ pathHelpersFilePath: '~/lib/utils/path_helpers/project', testCases });

describe('when shorthand project path helper is not provided the projectFullPath argument', () => {
  it('throws an error', async () => {
    const { editProjectPath } = await import('~/lib/utils/path_helpers/project');

    expect(() => {
      editProjectPath();
    }).toThrow(new Error('Route missing required keys: projectFullPath'));
  });
});

describe('when shorthand project path helper is not provided the projectFullPath argument as a string', () => {
  it('throws an error', async () => {
    const { editProjectPath } = await import('~/lib/utils/path_helpers/project');

    expect(() => {
      editProjectPath({ projectFullPath: '/foo/bar/baz' });
    }).toThrow(new Error('projectFullPath must be a string'));
  });
});
