import { imageAdapter } from '~/rapid_diffs/adapters/image_viewer';
import { setHTMLFixture } from 'helpers/fixtures';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';

jest.mock('~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue', () => ({
  props: jest.requireActual('~/vue_shared/components/diff_viewer/viewers/image_diff_viewer.vue')
    .default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-image-diff-viewer': true,
        'data-old-path': this.oldPath,
        'data-new-path': this.newPath,
        'data-old-size': this.oldSize,
        'data-new-size': this.newSize,
        'data-diff-mode': this.diffMode,
        'data-encode-path': this.encodePath.toString(),
      },
    });
  },
}));

describe('imageAdapter', () => {
  const imageData = {
    old_path: '/old',
    new_path: '/old',
    old_size: '10',
    new_size: '20',
    diff_mode: 'replaced',
  };

  const getDiffFile = () => document.querySelector('diff-file');
  const getDiffViewerApp = () => document.querySelector('[data-image-diff-viewer]');

  const mount = () => {
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify({ viewer: 'image' })}'>
        <div>
          <div data-image-data='${JSON.stringify(imageData)}'>
            <div data-image-view></div>
          </div>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { image: [imageAdapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  it('shows image diff', () => {
    mount();
    expect(getDiffViewerApp().dataset).toMatchObject({
      oldPath: imageData.old_path,
      newPath: imageData.new_path,
      oldSize: imageData.old_size,
      newSize: imageData.new_size,
      diffMode: imageData.diff_mode,
      encodePath: 'false',
    });
  });
});
