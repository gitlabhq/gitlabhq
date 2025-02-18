import { DiffFile } from '~/rapid_diffs/diff_file';
import { ToggleFileAdapter } from '~/rapid_diffs/toggle_file/adapter';

describe('Diff File Toggle Behavior', () => {
  // In our version of Jest/JSDOM we cannot use
  //
  // - CSS "&" nesting (baseline 2023)
  // - Element.checkVisibility (baseline 2024)
  // - :has (baseline 2023)
  //
  // so this cannot test CSS (which is a majority of our behavior), and must assume that
  // browser CSS is working as documented when we tweak HTML attributes
  const html = `
    <diff-file data-viewer="any">
      <div class="rd-diff-file">
        <div class="rd-diff-file-header" data-testid="rd-diff-file-header">
        <div class="rd-diff-file-toggle gl-mr-2"><
          <button data-opened="" data-click="toggleFile" aria-label="Hide file contents" type="button"></button>
          <button data-closed="" data-click="toggleFile" aria-label="Show file contents" type="button"></button>
        </div>
      </div>
      <div data-file-body=""><!-- body content --></div>
      <diff-file-mounted></diff-file-mounted>
    </diff-file>
  `;

  function get(element) {
    const elements = {
      file: () => document.querySelector('diff-file'),
      hide: () => get('file').querySelector('button[data-opened]'),
      show: () => get('file').querySelector('button[data-closed]'),
      body: () => get('file').querySelector('[data-file-body]'),
    };

    return elements[element]?.();
  }

  function assignAdapter(customAdapter) {
    get('file').adapterConfig = { any: [customAdapter] };
  }

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  beforeEach(() => {
    document.body.innerHTML = html;
    assignAdapter(ToggleFileAdapter);
    get('file').mount();
  });

  it('starts with the file body visible', () => {
    expect(get('body').hidden).toEqual(false);
  });

  it('marks the body hidden and focuses the other button when the hide button is clicked', () => {
    const show = get('show');
    const hide = get('hide');
    const body = get('body');

    hide.click();

    expect(body.hidden).toEqual(true);
    expect(document.activeElement).toEqual(show);
  });
});
