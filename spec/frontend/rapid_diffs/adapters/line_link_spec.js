import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { INVISIBLE, VISIBLE } from '~/rapid_diffs/adapter_events';
import { lineLinkAdapter } from '~/rapid_diffs/adapters/line_link';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/common_utils';
import { scrollTo } from '~/lib/utils/scroll_utils';

jest.mock('~/lib/utils/scroll_utils', () => ({
  ...jest.requireActual('~/lib/utils/scroll_utils'),
  scrollTo: jest.fn(),
  scrollToElement: jest.fn(),
}));

describe('lineLinkAdapter', () => {
  const getComponent = () => document.querySelector('diff-file');
  const getLink = () => document.querySelector(`[data-line-number]`);
  const getTarget = () => document.querySelector('#line_abc_20');

  const mount = ({ appData = {} } = {}) => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file id="abc" data-file-data='${JSON.stringify({ viewer })}'>
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
    getLink().click();
    expect(getTarget().classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(true);
    expect(window.location.hash).toBe('#line_abc_20');
    expect(scrollTo).toHaveBeenCalledWith({ left: 0, top: 0 });
  });

  it('does nothing when file becomes invisible', () => {
    mount();
    show();
    hide();
    expect(getTarget().classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(false);
    expect(window.location.hash).toBe('');
    expect(scrollTo).not.toHaveBeenCalled();
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
});
