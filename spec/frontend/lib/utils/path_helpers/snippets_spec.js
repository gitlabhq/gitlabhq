// To run this spec locally first run `bundle exec rake gitlab:js:routes`

import { sharedPathHelperTests } from './shared';

const testCases = [
  {
    pathHelperName: 'snippetNotesPath',
    args: ['1', { search: 'foo bar', format: 'json' }],
    baseExpected: '/-/snippets/1/notes.json?search=foo%20bar',
  },
  {
    pathHelperName: 'snippetBlobRawPath',
    args: [1, 'master', 'foo'],
    baseExpected: '/-/snippets/1/raw/master/foo',
  },
];

sharedPathHelperTests({ pathHelpersFilePath: '~/lib/utils/path_helpers/snippets', testCases });
