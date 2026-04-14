// To run this spec locally first run `bundle exec rake gitlab:js:routes`

import { sharedPathHelperTests } from './shared';

const testCases = [
  {
    pathHelperName: 'adminProjectPath',
    args: ['foo/bar/baz', { search: 'foo bar' }],
    baseExpected: '/admin/projects/foo/bar/baz?search=foo%20bar',
  },
  {
    pathHelperName: 'adminProjectRunnerProjectPath',
    args: ['foo/bar/baz', 1],
    baseExpected: '/admin/projects/foo/bar/baz/runner_projects/1',
  },
  {
    pathHelperName: 'adminProjectRunnerProjectPath',
    args: ['foo/bar/baz', { id: 1 }],
    baseExpected: '/admin/projects/foo/bar/baz/runner_projects/1',
  },
  {
    pathHelperName: 'overridesAdminApplicationSettingsIntegrationPath',
    args: [1, { search: 'foo bar', page: '1', format: 'json', anchor: 'js-visibility-settings' }],
    baseExpected:
      '/admin/application_settings/integrations/1/overrides.json?search=foo%20bar&page=1#js-visibility-settings',
  },
  {
    pathHelperName: 'adminApplicationSettingsPath',
    args: [{ anchor: 'js-visibility-settings' }],
    baseExpected: '/admin/application_settings#js-visibility-settings',
  },
];

sharedPathHelperTests({ pathHelpersFilePath: '~/lib/utils/path_helpers/admin', testCases });
