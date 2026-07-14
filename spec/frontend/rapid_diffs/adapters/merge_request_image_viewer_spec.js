import { mergeRequestImageViewerAdapter } from '~/rapid_diffs/adapters/merge_request_image_viewer';
import { setHTMLFixture } from 'helpers/fixtures';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';

const mockStore = { id: 'mergeRequestDiscussionsStore' };

jest.mock('~/merge_request/stores/merge_request_discussions', () => ({
  useMergeRequestDiscussions: () => mockStore,
}));

jest.mock('~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue', () => ({
  props: jest.requireActual('~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue')
    .default.props,
  inject: ['store', 'userPermissions', 'endpoints', 'noteableType'],
  render(h) {
    const { store, userPermissions, endpoints, noteableType } = this;
    return h('div', {
      attrs: {
        id: 'image-viewer',
        'data-props': JSON.stringify(this.$props),
        'data-injected': JSON.stringify({
          store,
          userPermissions,
          endpoints,
          noteableType,
        }),
      },
    });
  },
}));

describe('mergeRequestImageViewerAdapter', () => {
  const imageData = {
    old_path: '/old',
    new_path: '/new',
    old_size: '10',
    new_size: '20',
    diff_mode: 'replaced',
  };
  const diffRefs = { base_sha: 'base', head_sha: 'head', start_sha: 'start' };
  const appData = {
    userPermissions: 'userPermissions',
    discussionsEndpoint: 'discussionsEndpoint',
    previewMarkdownEndpoint: 'previewMarkdownEndpoint',
    markdownDocsEndpoint: 'markdownDocsEndpoint',
    registerPath: 'registerPath',
    signInPath: 'signInPath',
    reportAbusePath: 'reportAbusePath',
    noteableType: 'MergeRequest',
  };

  const getDiffFile = () => document.querySelector('diff-file');
  const getDiffViewerApp = () => document.querySelector('#image-viewer');

  const mount = () => {
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify({ viewer: 'image', old_path: '/old', new_path: '/new', diff_refs: diffRefs })}'>
        <div>
          <div data-image-data='${JSON.stringify(imageData)}'>
            <div data-image-view></div>
          </div>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { image: [mergeRequestImageViewerAdapter] },
      appData,
      unobserve: jest.fn(),
    });
  };

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  it('mounts the image diff viewer with discussions', () => {
    mount();
    const { props, injected } = getDiffViewerApp().dataset;
    const {
      imageData: imageDataAttr,
      oldPath,
      newPath,
      diffRefs: diffRefsProp,
    } = JSON.parse(props);
    const { store, userPermissions, endpoints, noteableType } = JSON.parse(injected);

    expect(imageDataAttr).toMatchObject(imageData);
    expect(oldPath).toBe('/old');
    expect(newPath).toBe('/new');
    expect(diffRefsProp).toStrictEqual(diffRefs);
    expect(noteableType).toBe('MergeRequest');
    expect(store).toStrictEqual(mockStore);
    expect(userPermissions).toBe('userPermissions');
    expect(endpoints).toMatchObject({ discussions: 'discussionsEndpoint' });
  });
});
