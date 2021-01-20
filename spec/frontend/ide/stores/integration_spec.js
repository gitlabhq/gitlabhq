import { decorateFiles } from '~/ide/lib/files';
import { createStore } from '~/ide/stores';

const TEST_BRANCH = 'test_branch';
const TEST_NAMESPACE = 'test_namespace';
const TEST_PROJECT_ID = `${TEST_NAMESPACE}/test_project`;
const TEST_PATH_DIR = 'src';
const TEST_PATH = `${TEST_PATH_DIR}/foo.js`;
const TEST_CONTENT = `Lorem ipsum dolar sit
Lorem ipsum dolar
Lorem ipsum
Lorem
`;

jest.mock('~/ide/ide_router');

describe('IDE store integration', () => {
  let store;

  beforeEach(() => {
    store = createStore();
    store.replaceState({
      ...store.state,
      projects: {
        [TEST_PROJECT_ID]: {
          web_url: 'test_web_url',
          branches: [],
        },
      },
      currentProjectId: TEST_PROJECT_ID,
      currentBranchId: TEST_BRANCH,
    });
  });

  describe('with project and files', () => {
    beforeEach(() => {
      const { entries, treeList } = decorateFiles({
        data: [`${TEST_PATH_DIR}/`, TEST_PATH, 'README.md'],
      });

      Object.assign(entries[TEST_PATH], {
        raw: TEST_CONTENT,
      });

      store.replaceState({
        ...store.state,
        trees: {
          [`${TEST_PROJECT_ID}/${TEST_BRANCH}`]: {
            tree: treeList,
          },
        },
        entries,
      });
    });

    describe('when a file is deleted and readded', () => {
      beforeEach(() => {
        store.dispatch('deleteEntry', TEST_PATH);
        store.dispatch('createTempEntry', { name: TEST_PATH, type: 'blob' });
      });

      it('is added to staged as modified', () => {
        expect(store.state.stagedFiles).toEqual([
          expect.objectContaining({
            path: TEST_PATH,
            deleted: false,
            staged: true,
            changed: true,
            tempFile: false,
          }),
        ]);
      });

      it('cleans up after commit', () => {
        const expected = expect.objectContaining({
          path: TEST_PATH,
          staged: false,
          changed: false,
          tempFile: false,
          deleted: false,
        });
        store.dispatch('stageChange', TEST_PATH);

        store.dispatch('commit/updateFilesAfterCommit', { data: {} });

        expect(store.state.entries[TEST_PATH]).toEqual(expected);
        expect(store.state.entries[TEST_PATH_DIR].tree.find((x) => x.path === TEST_PATH)).toEqual(
          expected,
        );
      });
    });
  });
});
