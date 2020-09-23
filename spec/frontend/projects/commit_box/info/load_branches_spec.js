import axios from 'axios';
import waitForPromises from 'helpers/wait_for_promises';
import MockAdapter from 'axios-mock-adapter';
import { loadBranches } from '~/projects/commit_box/info/load_branches';

const mockCommitPath = '/commit/abcd/branches';
const mockBranchesRes =
  '<a href="/-/commits/master">master</a><span><a href="/-/commits/my-branch">my-branch</a></span>';

describe('~/projects/commit_box/info/load_branches', () => {
  let mock;
  let el;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(mockCommitPath).reply(200, mockBranchesRes);

    el = document.createElement('div');
    el.dataset.commitPath = mockCommitPath;
    el.innerHTML = '<div class="commit-info branches"><span class="spinner"/></div>';
  });

  it('loads and renders branches info', async () => {
    loadBranches(el);
    await waitForPromises();

    expect(el.innerHTML).toBe(`<div class="commit-info branches">${mockBranchesRes}</div>`);
  });

  it('does not load when no container is provided', async () => {
    loadBranches(null);
    await waitForPromises();

    expect(mock.history.get).toHaveLength(0);
  });

  describe('when braches request returns unsafe content', () => {
    beforeEach(() => {
      mock
        .onGet(mockCommitPath)
        .reply(200, '<a onload="alert(\'xss!\');" href="/-/commits/master">master</a>');
    });

    it('displays sanitized html', async () => {
      loadBranches(el);
      await waitForPromises();

      expect(el.innerHTML).toBe(
        '<div class="commit-info branches"><a href="/-/commits/master">master</a></div>',
      );
    });
  });

  describe('when braches request fails', () => {
    beforeEach(() => {
      mock.onGet(mockCommitPath).reply(500, 'Error!');
    });

    it('attempts to load and renders an error', async () => {
      loadBranches(el);
      await waitForPromises();

      expect(el.innerHTML).toBe(
        '<div class="commit-info branches">Failed to load branches. Please try again.</div>',
      );
    });
  });
});
