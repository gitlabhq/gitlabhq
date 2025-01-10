import { createTestingPinia } from '@pinia/testing';
import { INLINE_DIFF_VIEW_TYPE, INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import * as types from '~/diffs/store/mutation_types';
import * as utils from '~/diffs/store/utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { getDiffFileMock } from '../../mock_data/diff_file';

describe('DiffsStoreMutations', () => {
  createTestingPinia({ stubActions: false });
  let store;

  beforeEach(() => {
    store = useLegacyDiffs();
    store.$reset();
  });

  describe('SET_BASE_CONFIG', () => {
    it.each`
      prop                    | value
      ${'endpoint'}           | ${'/diffs/endpoint'}
      ${'projectPath'}        | ${'/root/project'}
      ${'endpointUpdateUser'} | ${'/user/preferences'}
      ${'diffViewType'}       | ${'parallel'}
    `('should set the $prop property into state', ({ prop, value }) => {
      store[types.SET_BASE_CONFIG]({ [prop]: value });

      expect(store[prop]).toEqual(value);
    });
  });

  describe('SET_LOADING', () => {
    it('should set loading state', () => {
      store[types.SET_LOADING](false);

      expect(store.isLoading).toEqual(false);
    });
  });

  describe('SET_BATCH_LOADING_STATE', () => {
    it('should set loading state', () => {
      store[types.SET_BATCH_LOADING_STATE](false);

      expect(store.batchLoadingState).toEqual(false);
    });
  });

  describe('SET_RETRIEVING_BATCHES', () => {
    it('should set retrievingBatches state', () => {
      store[types.SET_RETRIEVING_BATCHES](false);

      expect(store.retrievingBatches).toEqual(false);
    });
  });

  describe('SET_DIFF_FILES', () => {
    it('should set diffFiles in state', () => {
      store[types.SET_DIFF_FILES](['file', 'another file']);

      expect(store.diffFiles.length).toEqual(2);
    });
  });

  describe('SET_DIFF_METADATA', () => {
    it('should overwrite state with the camelCased data that is passed in', () => {
      const diffFileMockData = getDiffFileMock();
      store.$patch({
        diffFiles: [],
      });
      const diffMock = {
        diff_files: [diffFileMockData],
      };
      const metaMock = {
        other_key: 'value',
      };

      store[types.SET_DIFF_METADATA](diffMock);
      expect(store.diffFiles[0]).toEqual(diffFileMockData);

      store[types.SET_DIFF_METADATA](metaMock);
      expect(store.diffFiles[0]).toEqual(diffFileMockData);
      expect(store.otherKey).toEqual('value');
    });
  });

  describe('SET_DIFF_DATA_BATCH', () => {
    it('should set diff data batch type properly', () => {
      const mockFile = getDiffFileMock();
      store.$patch({
        diffFiles: [],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      });
      const diffMock = {
        diff_files: [mockFile],
      };

      store[types.SET_DIFF_DATA_BATCH](diffMock);

      expect(store.diffFiles[0].collapsed).toEqual(false);
      expect(store.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });

    it('should update diff position by default', () => {
      const mockFile = getDiffFileMock();
      store.$patch({
        diffFiles: [mockFile, { ...mockFile, file_hash: 'foo', file_path: 'foo' }],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      });
      const diffMock = {
        diff_files: [mockFile],
      };

      store[types.SET_DIFF_DATA_BATCH](diffMock);

      expect(store.diffFiles[1].file_hash).toBe(mockFile.file_hash);
      expect(store.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });

    it('should not update diff position', () => {
      const mockFile = getDiffFileMock();
      store.$patch({
        diffFiles: [mockFile, { ...mockFile, file_hash: 'foo', file_path: 'foo' }],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      });
      const diffMock = {
        diff_files: [mockFile],
        updatePosition: false,
      };

      store[types.SET_DIFF_DATA_BATCH](diffMock);

      expect(store.diffFiles[0].file_hash).toBe(mockFile.file_hash);
      expect(store.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });
  });

  describe('SET_COVERAGE_DATA', () => {
    it('should set coverage data properly', () => {
      store.$patch({ coverageFiles: {} });
      const coverage = { 'app.js': { 1: 0, 2: 1 } };

      store[types.SET_COVERAGE_DATA](coverage);

      expect(store.coverageFiles).toEqual(coverage);
      expect(store.coverageLoaded).toEqual(true);
    });
  });

  describe('SET_DIFF_TREE_ENTRY', () => {
    it('should set tree entry', () => {
      const file = getDiffFileMock();
      store.$patch({ treeEntries: { [file.file_path]: {} } });

      store[types.SET_DIFF_TREE_ENTRY](file);

      expect(store.treeEntries[file.file_path].diffLoaded).toBe(true);
    });
  });

  describe('SET_DIFF_VIEW_TYPE', () => {
    it('should set diff view type properly', () => {
      store[types.SET_DIFF_VIEW_TYPE](INLINE_DIFF_VIEW_TYPE);

      expect(store.diffViewType).toEqual(INLINE_DIFF_VIEW_TYPE);
    });
  });

  describe('ADD_CONTEXT_LINES', () => {
    it('should call utils.addContextLines with proper params', () => {
      const options = {
        lineNumbers: { oldLineNumber: 1, newLineNumber: 2 },
        contextLines: [
          {
            old_line: 1,
            new_line: 1,
            line_code: 'ff9200_1_1',
            discussions: [],
            hasForm: false,
            type: 'expanded',
          },
        ],
        fileHash: 'ff9200',
        params: {
          bottom: true,
        },
        isExpandDown: false,
        nextLineNumbers: {},
      };
      const diffFile = {
        file_hash: options.fileHash,
        [INLINE_DIFF_LINES_KEY]: [],
      };
      store.$patch({ diffFiles: [diffFile], diffViewType: 'viewType' });
      const lines = [{ old_line: 1, new_line: 1 }];

      jest.spyOn(utils, 'findDiffFile').mockImplementation(() => diffFile);
      jest.spyOn(utils, 'removeMatchLine').mockImplementation(() => null);
      jest.spyOn(utils, 'addLineReferences').mockImplementation(() => lines);
      jest.spyOn(utils, 'addContextLines').mockImplementation(() => null);

      store[types.ADD_CONTEXT_LINES](options);

      expect(utils.findDiffFile).toHaveBeenCalledWith(store.diffFiles, options.fileHash);
      expect(utils.removeMatchLine).toHaveBeenCalledWith(
        diffFile,
        options.lineNumbers,
        options.params.bottom,
      );

      expect(utils.addLineReferences).toHaveBeenCalledWith(
        options.contextLines,
        options.lineNumbers,
        options.params.bottom,
        options.isExpandDown,
        options.nextLineNumbers,
      );

      expect(utils.addContextLines).toHaveBeenCalledWith({
        inlineLines: diffFile[INLINE_DIFF_LINES_KEY],
        contextLines: options.contextLines,
        bottom: options.params.bottom,
        lineNumbers: options.lineNumbers,
        isExpandDown: false,
      });
    });
  });

  describe('ADD_COLLAPSED_DIFFS', () => {
    it('should update the state with the given data for the given file hash', () => {
      const fileHash = 123;
      store.$patch({
        diffFiles: [{}, { content_sha: 'abc', file_hash: fileHash, existing_field: 0 }],
      });
      const data = {
        diff_files: [
          {
            content_sha: 'abc',
            file_hash: fileHash,
            extra_field: 1,
            existing_field: 1,
            viewer: { name: 'text' },
          },
        ],
      };

      store[types.ADD_COLLAPSED_DIFFS]({ file: store.diffFiles[1], data });

      expect(store.diffFiles[1].file_hash).toEqual(fileHash);
      expect(store.diffFiles[1].existing_field).toEqual(1);
      expect(store.diffFiles[1].extra_field).toEqual(1);
    });
  });

  describe('SET_LINE_DISCUSSIONS_FOR_FILE', () => {
    it('should add discussions to the given line', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
    });

    it('should add discussions to the given file', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        type: 'file',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [],
            discussions: [],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0].discussions.length).toEqual(1);
      expect(store.diffFiles[0].discussions[0].id).toEqual(1);
    });

    it('should not duplicate discussions on line', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
    });

    it('updates existing discussion', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion: {
          ...discussion,
          resolved: true,
          notes: ['test'],
        },
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].notes.length).toBe(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].resolved).toBe(true);
    });

    it('should not duplicate inline diff discussions', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [
                  {
                    id: 1,
                    line_code: 'ABC_1',
                    diff_discussion: true,
                    resolvable: true,
                    original_position: diffPosition,
                    position: diffPosition,
                    diff_file: {
                      file_hash: 'ABC',
                    },
                  },
                ],
              },
              {
                line_code: 'ABC_2',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 2,
        line_code: 'ABC_2',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_2: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toBe(1);
    });

    it('should add legacy discussions to the given line', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        line_code: 'ABC_1',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        active: true,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
    });

    it('should add discussions by line_codes and positions attributes', () => {
      const diffPosition = {
        base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
        new_line: null,
        new_path: '500-lines-4.txt',
        old_line: 5,
        old_path: '500-lines-4.txt',
        start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      };

      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [],
              },
            ],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_2',
        line_codes: ['ABC_1'],
        diff_discussion: true,
        resolvable: true,
        original_position: {},
        position: {},
        positions: [diffPosition],
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode,
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions).toHaveLength(1);
      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toBe(1);
    });

    it('should add discussion to file', () => {
      store.$patch({
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            discussions: [],
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      });
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        diff_file: {
          file_hash: store.diffFiles[0].file_hash,
        },
      };

      store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
        discussion,
        diffPositionByLineCode: null,
      });

      expect(store.diffFiles[0].discussions.length).toEqual(1);
    });

    describe('expanded state', () => {
      it('should expand discussion by default', () => {
        const diffPosition = {
          base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
          head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
          new_line: null,
          new_path: '500-lines-4.txt',
          old_line: 5,
          old_path: '500-lines-4.txt',
          start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        };

        store.$patch({
          latestDiff: true,
          diffFiles: [
            {
              file_hash: 'ABC',
              [INLINE_DIFF_LINES_KEY]: [
                {
                  line_code: 'ABC_1',
                  discussions: [],
                },
              ],
            },
          ],
        });
        const discussion = {
          id: 1,
          line_code: 'ABC_2',
          line_codes: ['ABC_1'],
          diff_discussion: true,
          resolvable: true,
          original_position: {},
          position: {},
          positions: [diffPosition],
          diff_file: {
            file_hash: store.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode,
        });

        expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
      });

      it('should collapse resolved discussion', () => {
        const diffPosition = {
          base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
          head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
          new_line: null,
          new_path: '500-lines-4.txt',
          old_line: 5,
          old_path: '500-lines-4.txt',
          start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        };

        store.$patch({
          latestDiff: true,
          diffFiles: [
            {
              file_hash: 'ABC',
              [INLINE_DIFF_LINES_KEY]: [
                {
                  line_code: 'ABC_1',
                  discussions: [],
                },
              ],
            },
          ],
        });
        const discussion = {
          id: 1,
          line_code: 'ABC_2',
          line_codes: ['ABC_1'],
          diff_discussion: true,
          resolvable: true,
          original_position: {},
          position: {},
          positions: [diffPosition],
          diff_file: {
            file_hash: store.diffFiles[0].file_hash,
          },
          resolved: true,
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode,
        });

        expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(false);
      });

      it('should keep resolved state for expanded discussion update', () => {
        const diffPosition = {
          base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
          head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
          new_line: null,
          new_path: '500-lines-4.txt',
          old_line: 5,
          old_path: '500-lines-4.txt',
          start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        };

        store.$patch({
          latestDiff: true,
          diffFiles: [
            {
              file_hash: 'ABC',
              [INLINE_DIFF_LINES_KEY]: [
                {
                  line_code: 'ABC_1',
                  discussions: [],
                },
              ],
            },
          ],
        });
        const discussion = {
          id: 1,
          line_code: 'ABC_2',
          line_codes: ['ABC_1'],
          diff_discussion: true,
          resolvable: true,
          original_position: {},
          position: {},
          positions: [diffPosition],
          diff_file: {
            file_hash: store.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode,
        });

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion: { ...discussion, resolved: true },
          diffPositionByLineCode,
        });

        expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
      });

      it('should keep expanded state when re-adding existing discussions', () => {
        const diffPosition = {
          base_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
          head_sha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
          new_line: null,
          new_path: '500-lines-4.txt',
          old_line: 5,
          old_path: '500-lines-4.txt',
          start_sha: 'ed13df29948c41ba367caa757ab3ec4892509910',
        };

        store.$patch({
          latestDiff: true,
          diffFiles: [
            {
              file_hash: 'ABC',
              discussions: [],
              [INLINE_DIFF_LINES_KEY]: [
                {
                  line_code: 'ABC_1',
                  discussions: [],
                },
              ],
            },
          ],
        });
        const discussion = {
          id: 1,
          line_code: 'ABC_2',
          line_codes: ['ABC_1'],
          diff_discussion: true,
          resolvable: true,
          original_position: {},
          position: {},
          positions: [diffPosition],
          diff_file: {
            file_hash: store.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode,
        });

        store[types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](false);

        store[types.SET_LINE_DISCUSSIONS_FOR_FILE]({
          discussion,
          diffPositionByLineCode,
        });

        expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(false);
      });
    });
  });

  describe('REMOVE_LINE_DISCUSSIONS', () => {
    it('should remove the existing discussions on the given line', () => {
      store.$patch({
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [
              {
                line_code: 'ABC_1',
                discussions: [
                  {
                    id: 1,
                    line_code: 'ABC_1',
                    notes: [],
                  },
                  {
                    id: 2,
                    line_code: 'ABC_1',
                    notes: [],
                  },
                ],
              },
            ],
          },
        ],
      });

      store[types.REMOVE_LINE_DISCUSSIONS_FOR_FILE]({
        fileHash: 'ABC',
        lineCode: 'ABC_1',
      });

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(0);
    });
  });

  describe('TOGGLE_FOLDER_OPEN', () => {
    it('toggles entry opened prop', () => {
      store.$patch({
        treeEntries: {
          path: {
            opened: false,
          },
        },
      });

      store[types.TOGGLE_FOLDER_OPEN]('path');

      expect(store.treeEntries.path.opened).toBe(true);
    });
  });

  describe('SET_FOLDER_OPEN', () => {
    it('toggles entry opened prop', () => {
      store.$patch({
        treeEntries: {
          path: {
            opened: false,
          },
        },
      });

      store[types.SET_FOLDER_OPEN]({ path: 'path', opened: true });

      expect(store.treeEntries.path.opened).toBe(true);
    });
  });

  describe('TREE_ENTRY_DIFF_LOADING', () => {
    it('sets the entry loading state to true by default', () => {
      store.$patch({
        treeEntries: {
          path: {
            diffLoading: false,
          },
        },
      });

      store[types.TREE_ENTRY_DIFF_LOADING]({ path: 'path' });

      expect(store.treeEntries.path.diffLoading).toBe(true);
    });

    it('sets the entry loading state to the provided value', () => {
      store.$patch({
        treeEntries: {
          path: {
            diffLoading: true,
          },
        },
      });

      store[types.TREE_ENTRY_DIFF_LOADING]({ path: 'path', loading: false });

      expect(store.treeEntries.path.diffLoading).toBe(false);
    });
  });

  describe('SET_SHOW_TREE_LIST', () => {
    it('sets showTreeList', () => {
      store[types.SET_SHOW_TREE_LIST](true);

      expect(store.showTreeList).toBe(true, 'Failed to toggle showTreeList to true');
    });
  });

  describe('SET_CURRENT_DIFF_FILE', () => {
    it('updates currentDiffFileId', () => {
      store[types.SET_CURRENT_DIFF_FILE]('somefileid');

      expect(store.currentDiffFileId).toBe('somefileid');
    });
  });

  describe('SET_DIFF_FILE_VIEWED', () => {
    beforeEach(() => {
      store.viewedDiffFileIds = { 123: true };
    });

    it.each`
      id       | bool     | outcome
      ${'abc'} | ${true}  | ${{ 123: true, abc: true }}
      ${'123'} | ${false} | ${{ 123: false }}
    `('sets the viewed files list to $bool for the id $id', ({ id, bool, outcome }) => {
      store[types.SET_DIFF_FILE_VIEWED]({ id, seen: bool });

      expect(store.viewedDiffFileIds).toEqual(outcome);
    });
  });

  describe('Set highlighted row', () => {
    it('sets highlighted row', () => {
      store[types.SET_HIGHLIGHTED_ROW]('ABC_123');

      expect(store.highlightedRow).toBe('ABC_123');
    });
  });

  describe('TOGGLE_LINE_HAS_FORM', () => {
    it('sets hasForm on lines', () => {
      const file = {
        file_hash: 'hash',
        [INLINE_DIFF_LINES_KEY]: [
          { line_code: '123', hasForm: false },
          { line_code: '124', hasForm: false },
        ],
      };
      store.$patch({
        diffFiles: [file],
      });

      store[types.TOGGLE_LINE_HAS_FORM]({
        lineCode: '123',
        hasForm: true,
        fileHash: 'hash',
      });

      expect(file[INLINE_DIFF_LINES_KEY][0].hasForm).toBe(true);
      expect(file[INLINE_DIFF_LINES_KEY][1].hasForm).toBe(false);
    });
  });

  describe('SET_TREE_DATA', () => {
    it('sets treeEntries and tree in state', () => {
      store.$patch({
        treeEntries: {},
        tree: [],
        isTreeLoaded: false,
      });

      store[types.SET_TREE_DATA]({
        treeEntries: { file: { name: 'index.js' } },
        tree: ['tree'],
      });

      expect(store.treeEntries).toEqual({
        file: {
          name: 'index.js',
        },
      });

      expect(store.tree).toEqual(['tree']);
      expect(store.isTreeLoaded).toEqual(true);
    });
  });

  describe('SET_RENDER_TREE_LIST', () => {
    it('sets renderTreeList', () => {
      store.$patch({
        renderTreeList: true,
      });

      store[types.SET_RENDER_TREE_LIST](false);

      expect(store.renderTreeList).toBe(false);
    });
  });

  describe('SET_SHOW_WHITESPACE', () => {
    it('sets showWhitespace', () => {
      store.$patch({
        showWhitespace: true,
        diffFiles: ['test'],
      });

      store[types.SET_SHOW_WHITESPACE](false);

      expect(store.showWhitespace).toBe(false);
      expect(store.diffFiles).toEqual([]);
    });
  });

  describe('REQUEST_FULL_DIFF', () => {
    it('sets isLoadingFullFile to true', () => {
      store.$patch({
        diffFiles: [{ file_path: 'test', isLoadingFullFile: false }],
      });

      store[types.REQUEST_FULL_DIFF]('test');

      expect(store.diffFiles[0].isLoadingFullFile).toBe(true);
    });
  });

  describe('RECEIVE_FULL_DIFF_ERROR', () => {
    it('sets isLoadingFullFile to false', () => {
      store.$patch({
        diffFiles: [{ file_path: 'test', isLoadingFullFile: true }],
      });

      store[types.RECEIVE_FULL_DIFF_ERROR]('test');

      expect(store.diffFiles[0].isLoadingFullFile).toBe(false);
    });
  });

  describe('RECEIVE_FULL_DIFF_SUCCESS', () => {
    it('sets isLoadingFullFile to false', () => {
      store.$patch({
        diffFiles: [
          {
            file_path: 'test',
            isLoadingFullFile: true,
            isShowingFullFile: false,
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      });

      store[types.RECEIVE_FULL_DIFF_SUCCESS]({ filePath: 'test', data: [] });

      expect(store.diffFiles[0].isLoadingFullFile).toBe(false);
    });

    it('sets isShowingFullFile to true', () => {
      store.$patch({
        diffFiles: [
          {
            file_path: 'test',
            isLoadingFullFile: true,
            isShowingFullFile: false,
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      });

      store[types.RECEIVE_FULL_DIFF_SUCCESS]({ filePath: 'test', data: [] });

      expect(store.diffFiles[0].isShowingFullFile).toBe(true);
    });
  });

  describe('SET_FILE_COLLAPSED', () => {
    it('sets collapsed', () => {
      store.$patch({
        diffFiles: [{ file_path: 'test', viewer: { automaticallyCollapsed: false } }],
      });

      store[types.SET_FILE_COLLAPSED]({ filePath: 'test', collapsed: true });

      expect(store.diffFiles[0].viewer.automaticallyCollapsed).toBe(true);
    });
  });

  describe('SET_CURRENT_VIEW_DIFF_FILE_LINES', () => {
    it(`sets the highlighted lines`, () => {
      const file = { file_path: 'test', [INLINE_DIFF_LINES_KEY]: [] };
      store.$patch({
        diffFiles: [file],
      });

      store[types.SET_CURRENT_VIEW_DIFF_FILE_LINES]({
        filePath: 'test',
        lines: ['test'],
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test']);
    });
  });

  describe('ADD_CURRENT_VIEW_DIFF_FILE_LINES', () => {
    it('pushes to inline lines', () => {
      const file = { file_path: 'test', [INLINE_DIFF_LINES_KEY]: [] };
      store.$patch({
        diffFiles: [file],
      });

      store[types.ADD_CURRENT_VIEW_DIFF_FILE_LINES]({
        filePath: 'test',
        line: 'test',
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test']);

      store[types.ADD_CURRENT_VIEW_DIFF_FILE_LINES]({
        filePath: 'test',
        line: 'test2',
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test', 'test2']);
    });
  });

  describe('TOGGLE_DIFF_FILE_RENDERING_MORE', () => {
    it('toggles renderingLines on file', () => {
      const file = { file_path: 'test', renderingLines: false };
      store.$patch({
        diffFiles: [file],
      });

      store[types.TOGGLE_DIFF_FILE_RENDERING_MORE]('test');

      expect(file.renderingLines).toBe(true);

      store[types.TOGGLE_DIFF_FILE_RENDERING_MORE]('test');

      expect(file.renderingLines).toBe(false);
    });
  });

  describe('SET_DIFF_FILE_VIEWER', () => {
    it("should update the correct diffFile's viewer property", () => {
      store.$patch({
        diffFiles: [
          { file_path: 'SearchString', viewer: 'OLD VIEWER' },
          { file_path: 'OtherSearchString' },
          { file_path: 'SomeOtherString' },
        ],
      });

      store[types.SET_DIFF_FILE_VIEWER]({
        filePath: 'SearchString',
        viewer: 'NEW VIEWER',
      });

      expect(store.diffFiles[0].viewer).toEqual('NEW VIEWER');
      expect(store.diffFiles[1].viewer).not.toBeDefined();
      expect(store.diffFiles[2].viewer).not.toBeDefined();

      store[types.SET_DIFF_FILE_VIEWER]({
        filePath: 'OtherSearchString',
        viewer: 'NEW VIEWER',
      });

      expect(store.diffFiles[0].viewer).toEqual('NEW VIEWER');
      expect(store.diffFiles[1].viewer).toEqual('NEW VIEWER');
      expect(store.diffFiles[2].viewer).not.toBeDefined();
    });
  });

  describe('SET_SHOW_SUGGEST_POPOVER', () => {
    it('sets showSuggestPopover to false', () => {
      store.$patch({ showSuggestPopover: true });

      store[types.SET_SHOW_SUGGEST_POPOVER]();

      expect(store.showSuggestPopover).toBe(false);
    });
  });

  describe('SET_FILE_BY_FILE', () => {
    it.each`
      value    | opposite
      ${true}  | ${false}
      ${false} | ${true}
    `('sets viewDiffsFileByFile to $value', ({ value, opposite }) => {
      store.$patch({ viewDiffsFileByFile: opposite });

      store[types.SET_FILE_BY_FILE](value);

      expect(store.viewDiffsFileByFile).toBe(value);
    });
  });

  describe('SET_MR_FILE_REVIEWS', () => {
    it.each`
      newReviews          | oldReviews
      ${{ abc: ['123'] }} | ${{}}
      ${{ abc: [] }}      | ${{ abc: ['123'] }}
      ${{}}               | ${{ abc: ['123'] }}
    `('sets mrReviews to $newReviews', ({ newReviews, oldReviews }) => {
      store.$patch({ mrReviews: oldReviews });

      store[types.SET_MR_FILE_REVIEWS](newReviews);

      expect(store.mrReviews).toStrictEqual(newReviews);
    });
  });

  describe('TOGGLE_FILE_COMMENT_FORM', () => {
    it('toggles diff files hasCommentForm', () => {
      store.$patch({ diffFiles: [{ file_path: 'path', hasCommentForm: false }] });

      store[types.TOGGLE_FILE_COMMENT_FORM]('path');

      expect(store.diffFiles[0].hasCommentForm).toEqual(true);
    });
  });

  describe('SET_FILE_COMMENT_FORM', () => {
    it('toggles diff files hasCommentForm', () => {
      store.$patch({ diffFiles: [{ file_path: 'path', hasCommentForm: false }] });
      const expanded = true;

      store[types.SET_FILE_COMMENT_FORM]({ filePath: 'path', expanded });

      expect(store.diffFiles[0].hasCommentForm).toEqual(expanded);
    });
  });

  describe('ADD_DRAFT_TO_FILE', () => {
    it('adds draft to diff file', () => {
      store.$patch({ diffFiles: [{ file_path: 'path', drafts: [] }] });

      store[types.ADD_DRAFT_TO_FILE]({ filePath: 'path', draft: 'test' });

      expect(store.diffFiles[0].drafts.length).toEqual(1);
      expect(store.diffFiles[0].drafts[0]).toEqual('test');
    });
  });

  describe('SET_FILE_FORCED_OPEN', () => {
    it('sets the forceOpen property of a diff file viewer correctly', () => {
      store.$patch({ diffFiles: [{ file_path: 'abc', viewer: { forceOpen: 'not-a-boolean' } }] });

      store[types.SET_FILE_FORCED_OPEN]({ filePath: 'abc', force: true });

      expect(store.diffFiles[0].viewer.forceOpen).toBe(true);
    });
  });

  describe('TOGGLE_FILE_DISCUSSION_EXPAND', () => {
    const fileHash = 'foo';

    it('expands collapsed discussion', () => {
      const discussion = {
        diff_file: { file_hash: fileHash },
        expandedOnDiff: false,
      };
      store.$patch({
        diffFiles: [{ file_hash: fileHash, discussions: [discussion] }],
      });

      store[types.TOGGLE_FILE_DISCUSSION_EXPAND]({ discussion });

      expect(store.diffFiles[0].discussions[0].expandedOnDiff).toBe(true);
    });

    it('collapses expanded discussion', () => {
      const discussion = {
        diff_file: { file_hash: fileHash },
        expandedOnDiff: true,
      };
      store.$patch({
        diffFiles: [{ file_hash: fileHash, discussions: [discussion] }],
      });

      store[types.TOGGLE_FILE_DISCUSSION_EXPAND]({ discussion });

      expect(store.diffFiles[0].discussions[0].expandedOnDiff).toBe(false);
    });
  });

  describe('SET_EXPAND_ALL_DIFF_DISCUSSIONS', () => {
    it('expands all discussions', () => {
      store.$patch({
        diffFiles: [
          {
            [INLINE_DIFF_LINES_KEY]: [
              { line_code: 'foo', discussions: [{}], discussionsExpanded: false },
            ],
            discussions: [{ expandedOnDiff: false }],
          },
          {
            [INLINE_DIFF_LINES_KEY]: [],
            discussions: [{ expandedOnDiff: false }],
          },
        ],
      });

      store[types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](true);

      expect(store.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
      expect(store.diffFiles[0].discussions[0].expandedOnDiff).toBe(true);
      expect(store.diffFiles[1].discussions[0].expandedOnDiff).toBe(true);
    });
  });

  describe('SET_LINKED_FILE_HASH', () => {
    it('sets linked file hash', () => {
      const file = getDiffFileMock();

      store[types.SET_LINKED_FILE_HASH](file.file_hash);

      expect(store.linkedFileHash).toBe(file.file_hash);
    });
  });

  describe('SET_COLLAPSED_STATE_FOR_ALL_FILES', () => {
    it('sets collapsed state for all files', () => {
      store.diffFiles = [getDiffFileMock(), getDiffFileMock()];

      store[types.SET_COLLAPSED_STATE_FOR_ALL_FILES]({ collapsed: true });

      expect(
        store.diffFiles.every(
          ({ viewer }) => viewer.manuallyCollapsed && !viewer.automaticallyCollapsed,
        ),
      ).toBe(true);
    });
  });
});
