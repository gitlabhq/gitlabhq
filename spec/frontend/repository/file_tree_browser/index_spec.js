import { setActivePinia } from 'pinia';
import { nextTick } from 'vue';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import initFileTreeBrowser from '~/repository/file_tree_browser/index';
import { useMainContainer } from '~/pinia/global_stores/main_container';
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

jest.mock('~/pinia/global_stores/main_container', () => ({ useMainContainer: jest.fn() }));

describe('initFileTreeBrowser', () => {
  let mockMainContainerStore;
  const getFileTreeBrowserComponent = () =>
    document.querySelector('[data-file-tree-browser-component]');

  beforeEach(() => {
    setActivePinia(pinia);
    setHTMLFixture('<div id="js-file-browser"></div>');
    mockMainContainerStore = {
      isCompact: false,
      isIntermediate: false,
      isWide: true,
    };

    useMainContainer.mockReturnValue(mockMainContainerStore);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe.each`
    routeName            | isCompactSize | expectedVisible
    ${'blobPathDecoded'} | ${true}       | ${false}
    ${'blobPathDecoded'} | ${false}      | ${true}
    ${'projectRoot'}     | ${false}      | ${false}
  `(
    'visibility logic when route is $routeName, compact screen: $isCompactSize',
    ({ routeName, isCompactSize, expectedVisible }) => {
      it(`${expectedVisible ? 'shows' : 'hides'} file tree browser`, async () => {
        mockMainContainerStore.isCompact = isCompactSize;
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
