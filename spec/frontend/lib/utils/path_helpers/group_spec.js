// To run this spec locally first run `bundle exec rake gitlab:js:routes`

import { sharedPathHelperTests } from './shared';

const testCases = [
  {
    pathHelperName: 'editGroupPath',
    args: ['foo/bar'],
    baseExpected: '/groups/foo/bar/-/edit',
  },
  {
    pathHelperName: 'editGroupPath',
    args: [
      'foo/bar',
      { search: 'foo bar', page: '1', format: 'json', anchor: 'js-visibility-settings' },
    ],
    baseExpected: '/groups/foo/bar/-/edit.json?search=foo%20bar&page=1#js-visibility-settings',
  },
];

sharedPathHelperTests({ pathHelpersFilePath: '~/lib/utils/path_helpers/group', testCases });
