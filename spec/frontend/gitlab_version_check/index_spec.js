import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initGitlabVersionCheck from '~/gitlab_version_check';
import {
  VERSION_CHECK_BADGE_NO_PROP_FIXTURE,
  VERSION_CHECK_BADGE_NO_SEVERITY_FIXTURE,
  VERSION_CHECK_BADGE_FIXTURE,
  VERSION_CHECK_BADGE_FINDER,
  VERSION_BADGE_TEXT,
  SECURITY_MODAL_FIXTURE,
  SECURITY_MODAL_FINDER,
  SECURITY_MODAL_TEXT,
} from './mock_data';

describe('initGitlabVersionCheck', () => {
  let wrapper;

  const createApp = (fixture) => {
    setHTMLFixture(fixture);
    initGitlabVersionCheck();
    wrapper = createWrapper(document.body);
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
    ${'with security modal el'}                           | ${SECURITY_MODAL_FIXTURE}                                    | ${[SECURITY_MODAL_FINDER]}                             | ${[SECURITY_MODAL_TEXT]}
    ${'with security modal and version badge els'}        | ${`${SECURITY_MODAL_FIXTURE}${VERSION_CHECK_BADGE_FIXTURE}`} | ${[SECURITY_MODAL_FINDER, VERSION_CHECK_BADGE_FINDER]} | ${[SECURITY_MODAL_TEXT, VERSION_BADGE_TEXT]}
  `('$description', ({ fixture, finders, componentTexts }) => {
    beforeEach(() => {
      createApp(fixture);
    });

    it(`correctly renders the Version Check Components`, () => {
      const renderedComponentTexts = finders.map((f) => wrapper.find(f)?.element?.innerText.trim());

      expect(renderedComponentTexts).toStrictEqual(componentTexts);
    });
  });
});
