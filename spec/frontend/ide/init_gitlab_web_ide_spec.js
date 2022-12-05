import { start } from '@gitlab/web-ide';
import { initGitlabWebIDE } from '~/ide/init_gitlab_web_ide';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('@gitlab/web-ide');

const ROOT_ELEMENT_ID = 'ide';
const TEST_NONCE = 'test123nonce';
const TEST_PROJECT_PATH = 'group1/project1';
const TEST_BRANCH_NAME = '12345-foo-patch';
const TEST_GITLAB_URL = 'https://test-gitlab/';
const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/webpack/assets/gitlab-web-ide/public/path';

describe('ide/init_gitlab_web_ide', () => {
  const createRootElement = () => {
    const el = document.createElement('div');

    el.id = ROOT_ELEMENT_ID;
    // why: We'll test that this class is removed later
    el.classList.add('test-class');
    el.dataset.projectPath = TEST_PROJECT_PATH;
    el.dataset.cspNonce = TEST_NONCE;
    el.dataset.branchName = TEST_BRANCH_NAME;

    document.body.append(el);
  };
  const findRootElement = () => document.getElementById(ROOT_ELEMENT_ID);
  const act = () => initGitlabWebIDE(findRootElement());

  beforeEach(() => {
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = TEST_GITLAB_WEB_IDE_PUBLIC_PATH;
    window.gon.gitlab_url = TEST_GITLAB_URL;

    createRootElement();

    act();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('calls start with element', () => {
    expect(start).toHaveBeenCalledTimes(1);
    expect(start).toHaveBeenCalledWith(findRootElement(), {
      baseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      projectPath: TEST_PROJECT_PATH,
      ref: TEST_BRANCH_NAME,
      gitlabUrl: TEST_GITLAB_URL,
      nonce: TEST_NONCE,
    });
  });

  it('clears classes and data from root element', () => {
    const rootEl = findRootElement();

    // why: Snapshot to test that the element was cleaned including `test-class`
    expect(rootEl.outerHTML).toBe(
      '<div id="ide" class="gl--flex-center gl-relative gl-h-full"></div>',
    );
  });
});
