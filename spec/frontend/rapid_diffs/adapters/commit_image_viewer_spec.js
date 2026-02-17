import { commitImageViewerAdapter } from '~/rapid_diffs/adapters/commit_image_viewer';
import { setHTMLFixture } from 'helpers/fixtures';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';

jest.mock('~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue', () => ({
  props: jest.requireActual('~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue')
    .default.props,
  inject: ['userPermissions', 'endpoints', 'noteableType'],
  render(h) {
    const { userPermissions, endpoints, noteableType } = this;
    return h('div', {
      attrs: {
        id: 'image-viewer',
        'data-props': JSON.stringify(this.$props),
        'data-injected': JSON.stringify({
          userPermissions,
          endpoints,
          noteableType,
        }),
      },
    });
  },
}));

describe('commitImageViewerAdapter', () => {
  const imageData = {
    old_path: '/old',
    new_path: '/old',
    old_size: '10',
    new_size: '20',
    diff_mode: 'replaced',
  };
  const appData = {
    userPermissions: 'userPermissions',
    discussionsEndpoint: 'discussionsEndpoint',
    previewMarkdownEndpoint: 'previewMarkdownEndpoint',
    markdownDocsEndpoint: 'markdownDocsEndpoint',
    registerPath: 'registerPath',
    signInPath: 'signInPath',
    reportAbusePath: 'reportAbusePath',
    noteableType: 'Commit',
  };

  const getDiffFile = () => document.querySelector('diff-file');
  const getDiffViewerApp = () => document.querySelector('#image-viewer');

  const mount = () => {
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify({ viewer: 'image', old_path: '/old', new_path: '/new' })}'>
        <div>
          <div data-image-data='${JSON.stringify(imageData)}'>
            <div data-image-view></div>
          </div>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { image: [commitImageViewerAdapter] },
      appData,
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  it('shows image diff', () => {
    mount();
    const { props, injected } = getDiffViewerApp().dataset;
    const { imageData: imageDataAttr, oldPath, newPath } = JSON.parse(props);
    const { userPermissions, endpoints, noteableType } = JSON.parse(injected);
    expect(imageDataAttr).toMatchObject(imageData);
    expect(oldPath).toBe('/old');
    expect(newPath).toBe('/new');
    expect(noteableType).toBe('Commit');
    expect(userPermissions).toStrictEqual(userPermissions);
    expect(endpoints).toStrictEqual(endpoints);
  });
});
