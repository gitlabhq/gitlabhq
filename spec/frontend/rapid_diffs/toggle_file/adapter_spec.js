import { DiffFile } from '~/rapid_diffs/diff_file';
import { ToggleFileAdapter } from '~/rapid_diffs/toggle_file/adapter';
import { COLLAPSE_FILE, EXPAND_FILE } from '~/rapid_diffs/events';

describe('Diff File Toggle Behavior', () => {
  function get(element) {
    const elements = {
      file: () => document.querySelector('diff-file'),
      hide: () => get('file').querySelector('button[data-opened]'),
      show: () => get('file').querySelector('button[data-closed]'),
      body: () => get('file').querySelector('[data-file-body]'),
    };

    return elements[element]?.();
  }

  const delegatedClick = (element) => {
    let event;
    element.addEventListener(
      'click',
      (e) => {
        event = e;
      },
      { once: true },
    );
    element.click();
    get('file').onClick(event);
  };

  const mount = () => {
    const viewer = 'any';
    document.body.innerHTML = `
      <diff-file data-file-data='${JSON.stringify({ viewer })}'>
        <div class="rd-diff-file">
          <div class="rd-diff-file-header" data-testid="rd-diff-file-header">
          <div class="rd-diff-file-toggle gl-mr-2"><
            <button data-opened="" data-click="toggleFile" aria-label="Hide file contents" type="button"></button>
            <button data-closed="" data-click="toggleFile" aria-label="Show file contents" type="button"></button>
          </div>
          <div data-file-body=""><!-- body content --></div>
        </div>
      </diff-file>
    `;
    get('file').mount({
      adapterConfig: { [viewer]: [ToggleFileAdapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    mount();
  });

  it('starts with the file body visible', () => {
    expect(get('body').hidden).toEqual(false);
  });

  it('marks the body hidden and focuses the other button when the hide button is clicked', () => {
    const show = get('show');
    const hide = get('hide');
    const body = get('body');

    delegatedClick(hide);

    expect(body.hidden).toEqual(true);
    expect(document.activeElement).toEqual(show);
  });

  it('collapses file', () => {
    get('file').trigger(COLLAPSE_FILE);
    expect(get('body').hidden).toEqual(true);
    expect(get('file').diffElement.dataset.collapsed).toEqual('true');
  });

  it('expands file', () => {
    get('file').trigger(EXPAND_FILE);
    expect(get('body').hidden).toEqual(false);
    expect(get('file').diffElement.dataset.collapsed).not.toEqual('true');
  });

  it('stops transition', () => {
    let tick;
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
      tick = () => cb();
    });

    delegatedClick(get('hide'));
    expect(get('show').style.transition).toBe('none');
    tick();
    expect(get('show').style.transition).toBe('');

    delegatedClick(get('show'));
    expect(get('hide').style.transition).toBe('none');
    tick();
    expect(get('hide').style.transition).toBe('');
  });
});
