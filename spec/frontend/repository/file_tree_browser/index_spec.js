import { setActivePinia } from 'pinia';
import { nextTick } from 'vue';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import initFileTreeBrowser from '~/repository/file_tree_browser/index';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { useViewport } from '~/pinia/global_stores/viewport';
import { pinia } from '~/pinia/instance';
import createRouter from '~/repository/router';
import createMockApollo from 'helpers/mock_apollo_helper';

jest.mock('~/repository/file_tree_browser/file_tree_browser.vue', () => ({
  props: jest.requireActual('~/repository/file_tree_browser/file_tree_browser.vue').default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-file-tree-browser-component': true,
        'data-project-path': this.projectPath,
        'data-current-ref': this.currentRef,
        'data-ref-type': this.refType,
      },
    });
  },
}));

describe('initFileTreeBrowser', () => {
  const getFileTreeBrowserComponent = () =>
    document.querySelector('[data-file-tree-browser-component]');

  beforeEach(() => {
    setActivePinia(pinia);
    useViewport().reset();
    useFileTreeBrowserVisibility().$reset();

    setHTMLFixture('<div id="js-file-browser"></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each`
    routeName            | isCompactViewport | fileTreeVisible | expectedVisible
    ${'blobPathDecoded'} | ${false}          | ${true}         | ${true}
    ${'blobPathDecoded'} | ${true}           | ${true}         | ${false}
    ${'blobPathDecoded'} | ${false}          | ${false}        | ${false}
    ${'projectRoot'}     | ${true}           | ${false}        | ${false}
  `(
    'visibility logic when route is $routeName, compact screen: $isCompactViewport, file tree visible: $fileTreeVisible',
    ({ routeName, isCompactViewport, fileTreeVisible, expectedVisible }) => {
      beforeEach(() => {
        useViewport().updateIsCompact(isCompactViewport);
        useFileTreeBrowserVisibility().setFileTreeVisibility(fileTreeVisible);
      });

      it(`${expectedVisible ? 'shows' : 'hides'} file tree browser`, async () => {
        const apolloProvider = createMockApollo([]);

        const options = {
          projectPath: 'gitlab-org/gitlab',
          ref: 'main',
          refType: 'heads',
        };

        const router = createRouter();
        await router.push({ name: routeName });

        await initFileTreeBrowser(router, options, apolloProvider);
        await nextTick();

        const component = getFileTreeBrowserComponent();

        if (expectedVisible) {
          expect(component.dataset).toMatchObject({
            projectPath: options.projectPath,
            currentRef: options.ref,
            refType: options.refType,
          });
        } else {
          expect(component).toBeNull();
        }
      });
    },
  );
});
