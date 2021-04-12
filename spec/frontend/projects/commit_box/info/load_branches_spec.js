import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { loadBranches } from '~/projects/commit_box/info/load_branches';

const mockCommitPath = '/commit/abcd/branches';
const mockBranchesRes =
  '<a href="/-/commits/main">main</a><span><a href="/-/commits/my-branch">my-branch</a></span>';

describe('~/projects/commit_box/info/load_branches', () => {
  let mock;

  const getElInnerHtml = () => document.querySelector('.js-commit-box-info').innerHTML;

  beforeEach(() => {
    setHTMLFixture(`
      <div class="js-commit-box-info" data-commit-path="${mockCommitPath}">
        <div class="commit-info branches">
          <span class="spinner"/>
        </div>
      </div>`);

    mock = new MockAdapter(axios);
    mock.onGet(mockCommitPath).reply(200, mockBranchesRes);
  });

  it('loads and renders branches info', async () => {
    loadBranches();
    await waitForPromises();

    expect(getElInnerHtml()).toMatchInterpolatedText(
      `<div class="commit-info branches">${mockBranchesRes}</div>`,
    );
  });

  it('does not load when no container is provided', async () => {
    loadBranches('.js-another-class');
    await waitForPromises();

    expect(mock.history.get).toHaveLength(0);
  });

  describe('when branches request returns unsafe content', () => {
    beforeEach(() => {
      mock
        .onGet(mockCommitPath)
        .reply(200, '<a onload="alert(\'xss!\');" href="/-/commits/main">main</a>');
    });

    it('displays sanitized html', async () => {
      loadBranches();
      await waitForPromises();

      expect(getElInnerHtml()).toMatchInterpolatedText(
        '<div class="commit-info branches"><a href="/-/commits/main">main</a></div>',
      );
    });
  });

  describe('when branches request fails', () => {
    beforeEach(() => {
      mock.onGet(mockCommitPath).reply(500, 'Error!');
    });

    it('attempts to load and renders an error', async () => {
      loadBranches();
      await waitForPromises();

      expect(getElInnerHtml()).toMatchInterpolatedText(
        '<div class="commit-info branches">Failed to load branches. Please try again.</div>',
      );
    });
  });
});
