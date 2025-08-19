import { setHTMLFixture } from 'helpers/fixtures';
import { createDiffFileMounted } from '~/rapid_diffs/web_components/diff_file_mounted';

describe('DiffFileMounted', () => {
  const appContext = {};
  const DiffFileStub = class extends HTMLElement {
    mount = jest.fn();
  };

  beforeAll(() => {
    const DiffFileMounted = createDiffFileMounted(appContext);
    customElements.define('diff-file', DiffFileStub);
    customElements.define('diff-file-mounted', DiffFileMounted);
  });

  it('mounts app context to the parent element', () => {
    setHTMLFixture(`<diff-file><diff-file-mounted></diff-file-mounted></diff-file>`);
    expect(document.querySelector('diff-file').mount).toHaveBeenCalledWith(appContext);
  });
});
