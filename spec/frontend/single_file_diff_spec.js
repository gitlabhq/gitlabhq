import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import SingleFileDiff from '~/single_file_diff';

describe('SingleFileDiff', () => {
  let mock = new MockAdapter(axios);
  const blobDiffPath = '/mock-path';

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock
      .onGet(blobDiffPath)
      .replyOnce(HTTP_STATUS_OK, { html: `<div class="diff-content">MOCKED</div>` });
  });

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  it('loads diff via axios exactly once for collapsed diffs', async () => {
    setHTMLFixture(`
    <div class="diff-file">
      <div class="js-file-title">
        MOCK TITLE
      </div>

      <div class="diff-content">
        <div class="diff-viewer" data-type="simple">
          <div
            class="nothing-here-block diff-collapsed"
            data-diff-for-path="${blobDiffPath}"
          >
            MOCK CONTENT
          </div>
        </div>
      </div>
    </div>
`);

    // Collapsed is the default state
    const diff = new SingleFileDiff(document.querySelector('.diff-file'));
    expect(diff.isOpen).toBe(false);
    expect(diff.content).toBeNull();
    expect(diff.diffForPath).toEqual(blobDiffPath);

    // Opening for the first time
    await diff.toggleDiff($(document.querySelector('.js-file-title')));
    expect(diff.isOpen).toBe(true);
    expect(diff.content).not.toBeNull();

    // Collapsing again
    await diff.toggleDiff($(document.querySelector('.js-file-title')));
    expect(diff.isOpen).toBe(false);
    expect(diff.content).not.toBeNull();

    mock.onGet(blobDiffPath).replyOnce(HTTP_STATUS_BAD_REQUEST, '');

    // Opening again
    await diff.toggleDiff($(document.querySelector('.js-file-title')));
    expect(diff.isOpen).toBe(true);
    expect(diff.content).not.toBeNull();

    expect(mock.history.get.length).toBe(1);
  });

  it('ignores user-defined diff path attributes', () => {
    setHTMLFixture(`
    <div class="diff-file">
      <div class="diff-content">
        <div class="diff-viewer" data-type="simple">
          <div class="note-text"><a data-diff-for-path="test/note/path">Test note</a></div>
          <div data-diff-for-path="${blobDiffPath}">MOCK CONTENT</div>
        </div>
      </div>
    </div>
`);
    const { diffForPath } = new SingleFileDiff(document.querySelector('.diff-file'));
    expect(diffForPath).toEqual(blobDiffPath);
  });

  it('does not load diffs via axios for already expanded diffs', async () => {
    setHTMLFixture(`
    <div class="diff-file">
      <div class="js-file-title">
        MOCK TITLE
      </div>

      <div class="diff-content">
        EXPANDED MOCK CONTENT
      </div>
    </div>
`);

    // Opened is the default state
    const diff = new SingleFileDiff(document.querySelector('.diff-file'));
    expect(diff.isOpen).toBe(true);
    expect(diff.content).not.toBeNull();
    expect(diff.diffForPath).toEqual(undefined);

    // Collapsing for the first time
    await diff.toggleDiff($(document.querySelector('.js-file-title')));
    expect(diff.isOpen).toBe(false);
    expect(diff.content).not.toBeNull();

    // Opening again
    await diff.toggleDiff($(document.querySelector('.js-file-title')));
    expect(diff.isOpen).toBe(true);

    expect(mock.history.get.length).toBe(0);
  });
});
