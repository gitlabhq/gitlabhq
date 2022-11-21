import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initGitlabVersionCheck from '~/gitlab_version_check';
import {
  VERSION_CHECK_BADGE_NO_PROP_FIXTURE,
  VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE,
  VERSION_CHECK_BADGE_FIXTURE,
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
    description                                           | fixture                                    | badgeTexts
    ${'with no version check badge el'}                   | ${'<div></div>'}                           | ${[]}
    ${'with version check badge el but no prop data'}     | ${VERSION_CHECK_BADGE_NO_PROP_FIXTURE}     | ${[undefined]}
    ${'with version check badge el but no severity data'} | ${VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE} | ${[undefined]}
    ${'with version check badge el and version data'}     | ${VERSION_CHECK_BADGE_FIXTURE}             | ${['Up to date']}
  `('$description', ({ fixture, badgeTexts }) => {
    beforeEach(() => {
      createApp(fixture);
    });

    it(`correctly renders the Version Check Badge`, () => {
      const vueAppInstances = vueApps.map((v) => v && createWrapper(v));
      const renderedBadgeTexts = vueAppInstances.map((i) => i?.text());

      expect(renderedBadgeTexts).toStrictEqual(badgeTexts);
    });
  });
});
