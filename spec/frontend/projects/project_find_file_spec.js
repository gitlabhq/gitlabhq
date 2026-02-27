import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ProjectFindFile, { appendBoldText, highlighter } from '~/projects/project_find_file';

jest.mock('~/lib/dompurify', () => ({
  addHook: jest.fn(),
  sanitize: jest.fn((val) => val),
}));

const BLOB_URL_TEMPLATE = `${TEST_HOST}/namespace/project/blob/main`;
const FILE_FIND_URL = `${TEST_HOST}/namespace/project/files/main?format=json`;
const FIND_TREE_URL = `${TEST_HOST}/namespace/project/tree/main`;
const TEMPLATE = `
  <div
    class="file-finder-holder tree-holder js-file-finder"
    data-blob-url-template="${BLOB_URL_TEMPLATE}"
    data-file-find-url="${FILE_FIND_URL}"
    data-find-tree-url="${FIND_TREE_URL}"
  >
    <input class="file-finder-input" id="file_find" />
    <div class="tree-content-holder">
      <div class="table-holder">
        <table class="files-slider tree-table">
          <tbody />
        </table>
      </div>
    </div>
  </div>`;

describe('ProjectFindFile', () => {
  let element;
  let mock;

  const getProjectFindFileInstance = (extraOptions) => {
    return new ProjectFindFile(element, {
      treeUrl: FIND_TREE_URL,
      blobUrlTemplate: BLOB_URL_TEMPLATE,
      ...extraOptions,
    });
  };

  const findFiles = () =>
    Array.from(element.querySelectorAll('.tree-table tr')).map((el) => ({
      text: el.textContent,
      href: el.querySelector('a').href,
    }));

  const files = [
    { path: 'fileA.txt', escaped: 'fileA.txt' },
    { path: 'fileB.txt', escaped: 'fileB.txt' },
    { path: 'fi#leC.txt', escaped: 'fi%23leC.txt' },
    { path: 'folderA/fileD.txt', escaped: 'folderA/fileD.txt' },
    { path: 'folder#B/fileE.txt', escaped: 'folder%23B/fileE.txt' },
    { path: 'folde?rC/fil#F.txt', escaped: 'folde%3FrC/fil%23F.txt' },
  ];

  beforeEach(() => {
    // Create a mock adapter for stubbing axios API requests
    mock = new MockAdapter(axios);

    const div = document.createElement('div');
    div.innerHTML = TEMPLATE.trim();
    element = div.firstChild;
    mock.onGet(FILE_FIND_URL).replyOnce(
      HTTP_STATUS_OK,
      files.map((x) => x.path),
    );
  });

  afterEach(() => {
    // Reset the mock adapter
    mock.restore();
    sanitize.mockClear();
  });

  describe('rendering without refType', () => {
    beforeEach(async () => {
      const instance = getProjectFindFileInstance();
      instance.load(FILE_FIND_URL); // axios call + subsequent render
      await waitForPromises();
    });

    it('loads and renders elements from remote server', () => {
      expect(findFiles()).toEqual(
        files.map(({ path, escaped }) => ({
          text: path,
          href: `${BLOB_URL_TEMPLATE}/${escaped}`,
        })),
      );
    });

    it('sanitizes search text', () => {
      const searchText = element.querySelector('.file-finder-input').value;

      expect(sanitize).toHaveBeenCalledWith(searchText);
    });
  });

  describe('with refType option', () => {
    beforeEach(async () => {
      const instance = getProjectFindFileInstance({ refType: 'heads' });
      instance.load(FILE_FIND_URL);
      await waitForPromises();
    });

    it('loads and renders elements from remote server', () => {
      expect(findFiles()).toEqual(
        files.map(({ path, escaped }) => ({
          text: path,
          href: `${BLOB_URL_TEMPLATE}/${escaped}?ref_type=heads`,
        })),
      );
    });
  });

  describe('appendBoldText', () => {
    it('creates a <b> element with the provided text and appends it', () => {
      const container = document.createElement('div');
      container.textContent = 'README';
      appendBoldText(container, '.md');

      expect(container.innerHTML).toBe('README<b>.md</b>');
    });
  });

  describe('highlighter', () => {
    it('wraps matched characters in <b> DOM elements', () => {
      const container = document.createElement('span');
      // Simulates searching "pj" in "package.json" - matches 'p' at 0, 'j' at 8
      highlighter(container, 'package.json', [0, 8]);

      expect(container.innerHTML).toBe('<b>p</b>ackage.<b>j</b>son');
      expect(container.querySelectorAll('b')).toHaveLength(2);
    });

    it('returns plain text when matches array is empty', () => {
      const container = document.createElement('span');
      highlighter(container, 'LICENSE', []);

      expect(container.textContent).toBe('LICENSE');
      expect(container.querySelectorAll('b')).toHaveLength(0);
    });
  });

  describe('goToBlob', () => {
    it('clicks the link of the selected row', async () => {
      const instance = getProjectFindFileInstance();
      instance.load(FILE_FIND_URL);
      await waitForPromises();

      const link = element.querySelector('.tree-item.selected a');
      const clickSpy = jest.spyOn(link, 'click').mockImplementation(() => {});

      instance.goToBlob();

      expect(clickSpy).toHaveBeenCalled();
    });
  });
});
