import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initGitlabVersionCheck from '~/gitlab_version_check';
import {
  VERSION_CHECK_BADGE_NO_PROP_FIXTURE,
  VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE,
  VERSION_CHECK_BADGE_FIXTURE,
  VERSION_CHECK_BADGE_FINDER,
  VERSION_BADGE_TEXT,
  SECURITY_PATCH_FIXTURE,
  SECURITY_PATCH_FINDER,
  SECURITY_BATCH_TEXT,
} from './mock_data';

describe('initGitlabVersionCheck', () => {
  let vueApps;

  const createApp = (fixture) => {
    setHTMLFixture(fixture);
    vueApps = initGitlabVersionCheck();
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each`
    description                                           | fixture                                                      | finders                                                | componentTexts
    ${'with no version check elements'}                   | ${'<div></div>'}                                             | ${[]}                                                  | ${[]}
    ${'with version check badge el but no prop data'}     | ${VERSION_CHECK_BADGE_NO_PROP_FIXTURE}                       | ${[VERSION_CHECK_BADGE_FINDER]}                        | ${[undefined]}
    ${'with version check badge el but no severity data'} | ${VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE}                   | ${[VERSION_CHECK_BADGE_FINDER]}                        | ${[undefined]}
    ${'with version check badge el and version data'}     | ${VERSION_CHECK_BADGE_FIXTURE}                               | ${[VERSION_CHECK_BADGE_FINDER]}                        | ${[VERSION_BADGE_TEXT]}
    ${'with security patch el'}                           | ${SECURITY_PATCH_FIXTURE}                                    | ${[SECURITY_PATCH_FINDER]}                             | ${[SECURITY_BATCH_TEXT]}
    ${'with security patch and version badge els'}        | ${`${SECURITY_PATCH_FIXTURE}${VERSION_CHECK_BADGE_FIXTURE}`} | ${[SECURITY_PATCH_FINDER, VERSION_CHECK_BADGE_FINDER]} | ${[SECURITY_BATCH_TEXT, VERSION_BADGE_TEXT]}
  `('$description', ({ fixture, finders, componentTexts }) => {
    beforeEach(() => {
      createApp(fixture);
    });

    it(`correctly renders the Version Check Components`, () => {
      const vueAppInstances = vueApps.map((v) => v && createWrapper(v));
      const renderedComponentTexts = vueAppInstances.map((v, index) =>
        v?.find(finders[index]).text(),
      );

      expect(renderedComponentTexts).toStrictEqual(componentTexts);
    });
  });
});
