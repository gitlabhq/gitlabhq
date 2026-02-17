import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { EXPANDED_LINES, INVISIBLE, VISIBLE } from '~/rapid_diffs/adapter_events';
import { lineLinkAdapter } from '~/rapid_diffs/adapters/line_link';
import { preventScrollToFragment } from '~/lib/utils/scroll_utils';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/scroll_utils');

describe('lineLinkAdapter', () => {
  const getComponent = () => document.querySelector('diff-file');
  const getLink = () => document.querySelector(`[data-line-number]`);
  const getAllLinks = () => document.querySelectorAll(`[data-line-number]`);

  const mount = ({ appData = {}, fileData = {} } = {}) => {
    const viewer = 'any';
    const defaultFileData = {
      viewer,
      oldPath: 'app/models/user.rb',
      newPath: 'app/models/user.rb',
      ...fileData,
    };
    document.body.innerHTML = `
      <diff-file id="abc" data-file-data='${JSON.stringify(defaultFileData)}'>
        <div id="wrapper">
          <div data-file-body>
            <table>
              <tbody>
                <tr id="line_abc_20">
                  <td data-position="old">
                    <a data-line-number="20" href="#line_abc_20"></a>
                  </td>
                  <td data-position="new">
                    <a data-line-number="21" href="#line_abc_20"></a>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </diff-file>
    `;
    getComponent().mount({
      adapterConfig: { [viewer]: [lineLinkAdapter] },
      appData,
      observe: jest.fn(),
      unobserve: jest.fn(),
    });
  };

  const show = () => {
    getComponent().trigger(VISIBLE);
  };

  const hide = () => {
    getComponent().trigger(INVISIBLE);
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  it('disables scroll to a target element', () => {
    mount();
    show();
    const link = getLink();
    link.addEventListener('click', (e) => e.preventDefault());
    link.click();
    expect(preventScrollToFragment).toHaveBeenCalled();
  });

  it('does nothing when file becomes invisible', () => {
    mount();
    show();
    hide();
    const link = getLink();
    link.addEventListener('click', (e) => e.preventDefault());
    link.click();
    expect(preventScrollToFragment).not.toHaveBeenCalled();
  });

  it('scrolls to legacy line link', () => {
    let clickEvent;
    document.addEventListener(
      'click',
      (event) => {
        clickEvent = event;
      },
      { once: true },
    );
    mount({ appData: { legacyFileFragment: { fileHash: 'abc', oldLine: '20', newLine: '21' } } });
    expect(clickEvent.target.href).toContain('#line_abc_20');
  });

  it('scrolls to legacy file link', () => {
    const spy = jest.spyOn(DiffFile.prototype, 'selectFile');
    mount({ appData: { legacyFileFragment: { fileHash: 'abc', oldLine: null, newLine: null } } });
    expect(spy).toHaveBeenCalled();
  });

  describe('linked file params in URLs', () => {
    beforeEach(() => {
      global.requestIdleCallback = jest.fn((cb) => cb());
      setWindowLocation('https://example.com/merge_requests/1');
    });

    it('adds linked file params to line links when file becomes visible', () => {
      mount({
        fileData: {
          oldPath: 'app/models/old_user.rb',
          newPath: 'app/models/new_user.rb',
        },
      });
      show();

      const links = getAllLinks();
      links.forEach((link) => {
        expect(link.href).toContain('old_path=app%2Fmodels%2Fold_user.rb');
        expect(link.href).toContain('new_path=app%2Fmodels%2Fnew_user.rb');
        expect(link.linked).toBe(true);
      });
    });

    it('adds file_path param when old and new paths are the same', () => {
      mount({
        fileData: {
          oldPath: 'app/models/user.rb',
          newPath: 'app/models/user.rb',
        },
      });
      show();

      const links = getAllLinks();
      links.forEach((link) => {
        expect(link.href).toContain('file_path=app%2Fmodels%2Fuser.rb');
        expect(link.href).not.toContain('old_path');
        expect(link.href).not.toContain('new_path');
        expect(link.linked).toBe(true);
      });
    });

    it('preserves line hash in the URL', () => {
      mount();
      show();

      const link = getLink();
      expect(link.href).toContain('#line_abc_20');
    });

    it('does not modify links that are already linked', () => {
      mount();
      show();

      const link = getLink();
      const originalHref = link.href;
      expect(link.linked).toBe(true);

      show();

      expect(link.href).toBe(originalHref);
    });

    it('adds linked file params on MOUNTED event via requestIdleCallback', () => {
      mount();

      expect(global.requestIdleCallback).toHaveBeenCalled();

      const links = getAllLinks();
      links.forEach((link) => {
        expect(link.href).toContain('file_path=app%2Fmodels%2Fuser.rb');
        expect(link.linked).toBe(true);
      });
    });

    it('adds linked file params on EXPANDED_LINES event', () => {
      mount();

      const newRow = document.createElement('tr');
      newRow.id = 'line_abc_30';
      newRow.innerHTML = `
        <td data-position="old">
          <a data-line-number="30" href="#line_abc_30"></a>
        </td>
        <td data-position="new">
          <a data-line-number="31" href="#line_abc_30"></a>
        </td>
      `;
      document.querySelector('tbody').appendChild(newRow);

      getComponent().trigger(EXPANDED_LINES);

      const allLinks = getAllLinks();
      expect(allLinks).toHaveLength(4);

      allLinks.forEach((link) => {
        expect(link.href).toContain('file_path=app%2Fmodels%2Fuser.rb');
        expect(link.linked).toBe(true);
      });
    });

    it('only processes line links once when visible', () => {
      mount();
      show();

      const link = getLink();
      const originalHref = link.href;

      show();
      show();

      expect(link.href).toBe(originalHref);
    });

    it('preserves existing query parameters in the URL', () => {
      setWindowLocation('https://example.com/merge_requests/1?view=parallel&diff_id=123');

      mount();
      show();

      const link = getLink();
      expect(link.href).toContain('view=parallel');
      expect(link.href).toContain('diff_id=123');
      expect(link.href).toContain('file_path=app%2Fmodels%2Fuser.rb');
    });

    it('removes existing file_path params before adding new ones', () => {
      setWindowLocation('https://example.com/merge_requests/1?file_path=other_file.rb');

      mount({
        fileData: {
          oldPath: 'app/models/user.rb',
          newPath: 'app/models/user.rb',
        },
      });
      show();

      const link = getLink();
      expect(link.href).toContain('file_path=app%2Fmodels%2Fuser.rb');
      expect(link.href).not.toContain('other_file.rb');
    });
  });
});
