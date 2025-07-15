import { DiffFile } from '~/rapid_diffs/diff_file';
import { INVISIBLE, VISIBLE } from '~/rapid_diffs/events';
import { LineLinkAdapter } from '~/rapid_diffs/line_link/adapter';
import { NO_SCROLL_TO_HASH_CLASS } from '~/lib/utils/common_utils';

describe('LineLinkAdapter', () => {
  const getComponent = () => document.querySelector('diff-file');
  const getLink = () => document.querySelector(`[data-line-number]`);
  const getTarget = () => document.querySelector('#target');

  const mount = () => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer })}'>
        <div id="wrapper">
          <div data-file-body>
            <a data-line-number="20" href="#target"></a>
            <div id="target"></div>
          </div>
        </div>
      </diff-file>
    `;
    getComponent().mount({
      adapterConfig: { [viewer]: [LineLinkAdapter] },
      appData: {},
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
    expect(window.location.hash).toBe('#target');
    expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
  });

  it('does nothing when file becomes invisible', () => {
    mount();
    show();
    hide();
    expect(getTarget().classList.contains(NO_SCROLL_TO_HASH_CLASS)).toBe(false);
    expect(window.location.hash).toBe('');
    expect(window.scrollTo).not.toHaveBeenCalled();
  });
});
