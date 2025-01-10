import { INLINE_DIFF_VIEW_TYPE, INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import createState from '~/diffs/store/modules/diff_state';
import * as types from '~/diffs/store/mutation_types';
import mutations from '~/diffs/store/mutations';
import * as utils from '~/diffs/store/utils';
import { getDiffFileMock } from '../mock_data/diff_file';

describe('DiffsStoreMutations', () => {
  describe('SET_BASE_CONFIG', () => {
    it.each`
      prop                    | value
      ${'endpoint'}           | ${'/diffs/endpoint'}
      ${'projectPath'}        | ${'/root/project'}
      ${'endpointUpdateUser'} | ${'/user/preferences'}
      ${'diffViewType'}       | ${'parallel'}
    `('should set the $prop property into state', ({ prop, value }) => {
      const state = {};

      mutations[types.SET_BASE_CONFIG](state, { [prop]: value });

      expect(state[prop]).toEqual(value);
    });
  });

  describe('SET_LOADING', () => {
    it('should set loading state', () => {
      const state = {};

      mutations[types.SET_LOADING](state, false);

      expect(state.isLoading).toEqual(false);
    });
  });

  describe('SET_BATCH_LOADING_STATE', () => {
    it('should set loading state', () => {
      const state = {};

      mutations[types.SET_BATCH_LOADING_STATE](state, false);

      expect(state.batchLoadingState).toEqual(false);
    });
  });

  describe('SET_RETRIEVING_BATCHES', () => {
    it('should set retrievingBatches state', () => {
      const state = {};

      mutations[types.SET_RETRIEVING_BATCHES](state, false);

      expect(state.retrievingBatches).toEqual(false);
    });
  });

  describe('SET_DIFF_FILES', () => {
    it('should set diffFiles in state', () => {
      const state = {};

      mutations[types.SET_DIFF_FILES](state, ['file', 'another file']);

      expect(state.diffFiles.length).toEqual(2);
    });

    it('should not set anything except diffFiles in state', () => {
      const state = {};

      mutations[types.SET_DIFF_FILES](state, ['file', 'another file']);

      expect(Object.keys(state)).toEqual(['diffFiles']);
    });
  });

  describe('SET_DIFF_METADATA', () => {
    it('should overwrite state with the camelCased data that is passed in', () => {
      const diffFileMockData = getDiffFileMock();
      const state = {
        diffFiles: [],
      };
      const diffMock = {
        diff_files: [diffFileMockData],
      };
      const metaMock = {
        other_key: 'value',
      };

      mutations[types.SET_DIFF_METADATA](state, diffMock);
      expect(state.diffFiles[0]).toEqual(diffFileMockData);

      mutations[types.SET_DIFF_METADATA](state, metaMock);
      expect(state.diffFiles[0]).toEqual(diffFileMockData);
      expect(state.otherKey).toEqual('value');
    });
  });

  describe('SET_DIFF_DATA_BATCH', () => {
    it('should set diff data batch type properly', () => {
      const mockFile = getDiffFileMock();
      const state = {
        diffFiles: [],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      };
      const diffMock = {
        diff_files: [mockFile],
      };

      mutations[types.SET_DIFF_DATA_BATCH](state, diffMock);

      expect(state.diffFiles[0].collapsed).toEqual(false);
      expect(state.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });

    it('should update diff position by default', () => {
      const mockFile = getDiffFileMock();
      const state = {
        diffFiles: [mockFile, { ...mockFile, file_hash: 'foo', file_path: 'foo' }],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      };
      const diffMock = {
        diff_files: [mockFile],
      };

      mutations[types.SET_DIFF_DATA_BATCH](state, diffMock);

      expect(state.diffFiles[1].file_hash).toBe(mockFile.file_hash);
      expect(state.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });

    it('should not update diff position', () => {
      const mockFile = getDiffFileMock();
      const state = {
        diffFiles: [mockFile, { ...mockFile, file_hash: 'foo', file_path: 'foo' }],
        treeEntries: { [mockFile.file_path]: { fileHash: mockFile.file_hash } },
      };
      const diffMock = {
        diff_files: [mockFile],
        updatePosition: false,
      };

      mutations[types.SET_DIFF_DATA_BATCH](state, diffMock);

      expect(state.diffFiles[0].file_hash).toBe(mockFile.file_hash);
      expect(state.treeEntries[mockFile.file_path].diffLoaded).toBe(true);
    });
  });

  describe('SET_COVERAGE_DATA', () => {
    it('should set coverage data properly', () => {
      const state = { coverageFiles: {} };
      const coverage = { 'app.js': { 1: 0, 2: 1 } };

      mutations[types.SET_COVERAGE_DATA](state, coverage);

      expect(state.coverageFiles).toEqual(coverage);
      expect(state.coverageLoaded).toEqual(true);
    });
  });

  describe('SET_DIFF_TREE_ENTRY', () => {
    it('should set tree entry', () => {
      const file = getDiffFileMock();
      const state = { treeEntries: { [file.file_path]: {} } };

      mutations[types.SET_DIFF_TREE_ENTRY](state, file);

      expect(state.treeEntries[file.file_path].diffLoaded).toBe(true);
    });
  });

  describe('SET_DIFF_VIEW_TYPE', () => {
    it('should set diff view type properly', () => {
      const state = {};

      mutations[types.SET_DIFF_VIEW_TYPE](state, INLINE_DIFF_VIEW_TYPE);

      expect(state.diffViewType).toEqual(INLINE_DIFF_VIEW_TYPE);
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
      const state = { diffFiles: [diffFile], diffViewType: 'viewType' };
      const lines = [{ old_line: 1, new_line: 1 }];

      jest.spyOn(utils, 'findDiffFile').mockImplementation(() => diffFile);
      jest.spyOn(utils, 'removeMatchLine').mockImplementation(() => null);
      jest.spyOn(utils, 'addLineReferences').mockImplementation(() => lines);
      jest.spyOn(utils, 'addContextLines').mockImplementation(() => null);

      mutations[types.ADD_CONTEXT_LINES](state, options);

      expect(utils.findDiffFile).toHaveBeenCalledWith(state.diffFiles, options.fileHash);
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
      const state = {
        diffFiles: [{}, { content_sha: 'abc', file_hash: fileHash, existing_field: 0 }],
      };
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

      mutations[types.ADD_COLLAPSED_DIFFS](state, { file: state.diffFiles[1], data });

      expect(state.diffFiles[1].file_hash).toEqual(fileHash);
      expect(state.diffFiles[1].existing_field).toEqual(1);
      expect(state.diffFiles[1].extra_field).toEqual(1);
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

      const state = {
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
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
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

      const state = {
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            [INLINE_DIFF_LINES_KEY]: [],
            discussions: [],
          },
        ],
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0].discussions.length).toEqual(1);
      expect(state.diffFiles[0].discussions[0].id).toEqual(1);
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

      const state = {
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
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
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

      const state = {
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
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion: {
          ...discussion,
          resolved: true,
          notes: ['test'],
        },
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].notes.length).toBe(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].resolved).toBe(true);
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

      const state = {
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
      };
      const discussion = {
        id: 2,
        line_code: 'ABC_2',
        diff_discussion: true,
        resolvable: true,
        original_position: diffPosition,
        position: diffPosition,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_2: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toBe(1);
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

      const state = {
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
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        active: true,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toEqual(1);
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

      const state = {
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
      };
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
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      const diffPositionByLineCode = {
        ABC_1: diffPosition,
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode,
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions).toHaveLength(1);
      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions[0].id).toBe(1);
    });

    it('should add discussion to file', () => {
      const state = {
        latestDiff: true,
        diffFiles: [
          {
            file_hash: 'ABC',
            discussions: [],
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      };
      const discussion = {
        id: 1,
        line_code: 'ABC_1',
        diff_discussion: true,
        resolvable: true,
        diff_file: {
          file_hash: state.diffFiles[0].file_hash,
        },
      };

      mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
        discussion,
        diffPositionByLineCode: null,
      });

      expect(state.diffFiles[0].discussions.length).toEqual(1);
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

        const state = {
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
        };
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
            file_hash: state.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion,
          diffPositionByLineCode,
        });

        expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
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

        const state = {
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
        };
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
            file_hash: state.diffFiles[0].file_hash,
          },
          resolved: true,
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion,
          diffPositionByLineCode,
        });

        expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(false);
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

        const state = {
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
        };
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
            file_hash: state.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion,
          diffPositionByLineCode,
        });

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion: { ...discussion, resolved: true },
          diffPositionByLineCode,
        });

        expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
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

        const state = {
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
        };
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
            file_hash: state.diffFiles[0].file_hash,
          },
        };

        const diffPositionByLineCode = {
          ABC_1: diffPosition,
        };

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion,
          diffPositionByLineCode,
        });

        mutations[types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](state, false);

        mutations[types.SET_LINE_DISCUSSIONS_FOR_FILE](state, {
          discussion,
          diffPositionByLineCode,
        });

        expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(false);
      });
    });
  });

  describe('REMOVE_LINE_DISCUSSIONS', () => {
    it('should remove the existing discussions on the given line', () => {
      const state = {
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
      };

      mutations[types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, {
        fileHash: 'ABC',
        lineCode: 'ABC_1',
      });

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussions.length).toEqual(0);
    });
  });

  describe('TOGGLE_FOLDER_OPEN', () => {
    it('toggles entry opened prop', () => {
      const state = {
        treeEntries: {
          path: {
            opened: false,
          },
        },
      };

      mutations[types.TOGGLE_FOLDER_OPEN](state, 'path');

      expect(state.treeEntries.path.opened).toBe(true);
    });
  });

  describe('SET_FOLDER_OPEN', () => {
    it('toggles entry opened prop', () => {
      const state = {
        treeEntries: {
          path: {
            opened: false,
          },
        },
      };

      mutations[types.SET_FOLDER_OPEN](state, { path: 'path', opened: true });

      expect(state.treeEntries.path.opened).toBe(true);
    });
  });

  describe('TREE_ENTRY_DIFF_LOADING', () => {
    it('sets the entry loading state to true by default', () => {
      const state = {
        treeEntries: {
          path: {
            diffLoading: false,
          },
        },
      };

      mutations[types.TREE_ENTRY_DIFF_LOADING](state, { path: 'path' });

      expect(state.treeEntries.path.diffLoading).toBe(true);
    });

    it('sets the entry loading state to the provided value', () => {
      const state = {
        treeEntries: {
          path: {
            diffLoading: true,
          },
        },
      };

      mutations[types.TREE_ENTRY_DIFF_LOADING](state, { path: 'path', loading: false });

      expect(state.treeEntries.path.diffLoading).toBe(false);
    });
  });

  describe('SET_SHOW_TREE_LIST', () => {
    it('sets showTreeList', () => {
      const state = createState();

      mutations[types.SET_SHOW_TREE_LIST](state, true);

      expect(state.showTreeList).toBe(true, 'Failed to toggle showTreeList to true');
    });
  });

  describe('SET_CURRENT_DIFF_FILE', () => {
    it('updates currentDiffFileId', () => {
      const state = createState();

      mutations[types.SET_CURRENT_DIFF_FILE](state, 'somefileid');

      expect(state.currentDiffFileId).toBe('somefileid');
    });
  });

  describe('SET_DIFF_FILE_VIEWED', () => {
    let state;

    beforeEach(() => {
      state = {
        viewedDiffFileIds: { 123: true },
      };
    });

    it.each`
      id       | bool     | outcome
      ${'abc'} | ${true}  | ${{ 123: true, abc: true }}
      ${'123'} | ${false} | ${{ 123: false }}
    `('sets the viewed files list to $bool for the id $id', ({ id, bool, outcome }) => {
      mutations[types.SET_DIFF_FILE_VIEWED](state, { id, seen: bool });

      expect(state.viewedDiffFileIds).toEqual(outcome);
    });
  });

  describe('Set highlighted row', () => {
    it('sets highlighted row', () => {
      const state = createState();

      mutations[types.SET_HIGHLIGHTED_ROW](state, 'ABC_123');

      expect(state.highlightedRow).toBe('ABC_123');
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
      const state = {
        diffFiles: [file],
      };

      mutations[types.TOGGLE_LINE_HAS_FORM](state, {
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
      const state = {
        treeEntries: {},
        tree: [],
        isTreeLoaded: false,
      };

      mutations[types.SET_TREE_DATA](state, {
        treeEntries: { file: { name: 'index.js' } },
        tree: ['tree'],
      });

      expect(state.treeEntries).toEqual({
        file: {
          name: 'index.js',
        },
      });

      expect(state.tree).toEqual(['tree']);
      expect(state.isTreeLoaded).toEqual(true);
    });
  });

  describe('SET_RENDER_TREE_LIST', () => {
    it('sets renderTreeList', () => {
      const state = {
        renderTreeList: true,
      };

      mutations[types.SET_RENDER_TREE_LIST](state, false);

      expect(state.renderTreeList).toBe(false);
    });
  });

  describe('SET_SHOW_WHITESPACE', () => {
    it('sets showWhitespace', () => {
      const state = {
        showWhitespace: true,
        diffFiles: ['test'],
      };

      mutations[types.SET_SHOW_WHITESPACE](state, false);

      expect(state.showWhitespace).toBe(false);
      expect(state.diffFiles).toEqual([]);
    });
  });

  describe('REQUEST_FULL_DIFF', () => {
    it('sets isLoadingFullFile to true', () => {
      const state = {
        diffFiles: [{ file_path: 'test', isLoadingFullFile: false }],
      };

      mutations[types.REQUEST_FULL_DIFF](state, 'test');

      expect(state.diffFiles[0].isLoadingFullFile).toBe(true);
    });
  });

  describe('RECEIVE_FULL_DIFF_ERROR', () => {
    it('sets isLoadingFullFile to false', () => {
      const state = {
        diffFiles: [{ file_path: 'test', isLoadingFullFile: true }],
      };

      mutations[types.RECEIVE_FULL_DIFF_ERROR](state, 'test');

      expect(state.diffFiles[0].isLoadingFullFile).toBe(false);
    });
  });

  describe('RECEIVE_FULL_DIFF_SUCCESS', () => {
    it('sets isLoadingFullFile to false', () => {
      const state = {
        diffFiles: [
          {
            file_path: 'test',
            isLoadingFullFile: true,
            isShowingFullFile: false,
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      };

      mutations[types.RECEIVE_FULL_DIFF_SUCCESS](state, { filePath: 'test', data: [] });

      expect(state.diffFiles[0].isLoadingFullFile).toBe(false);
    });

    it('sets isShowingFullFile to true', () => {
      const state = {
        diffFiles: [
          {
            file_path: 'test',
            isLoadingFullFile: true,
            isShowingFullFile: false,
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ],
      };

      mutations[types.RECEIVE_FULL_DIFF_SUCCESS](state, { filePath: 'test', data: [] });

      expect(state.diffFiles[0].isShowingFullFile).toBe(true);
    });
  });

  describe('SET_FILE_COLLAPSED', () => {
    it('sets collapsed', () => {
      const state = {
        diffFiles: [{ file_path: 'test', viewer: { automaticallyCollapsed: false } }],
      };

      mutations[types.SET_FILE_COLLAPSED](state, { filePath: 'test', collapsed: true });

      expect(state.diffFiles[0].viewer.automaticallyCollapsed).toBe(true);
    });
  });

  describe('SET_CURRENT_VIEW_DIFF_FILE_LINES', () => {
    it(`sets the highlighted lines`, () => {
      const file = { file_path: 'test', [INLINE_DIFF_LINES_KEY]: [] };
      const state = {
        diffFiles: [file],
      };

      mutations[types.SET_CURRENT_VIEW_DIFF_FILE_LINES](state, {
        filePath: 'test',
        lines: ['test'],
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test']);
    });
  });

  describe('ADD_CURRENT_VIEW_DIFF_FILE_LINES', () => {
    it('pushes to inline lines', () => {
      const file = { file_path: 'test', [INLINE_DIFF_LINES_KEY]: [] };
      const state = {
        diffFiles: [file],
      };

      mutations[types.ADD_CURRENT_VIEW_DIFF_FILE_LINES](state, {
        filePath: 'test',
        line: 'test',
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test']);

      mutations[types.ADD_CURRENT_VIEW_DIFF_FILE_LINES](state, {
        filePath: 'test',
        line: 'test2',
      });

      expect(file[INLINE_DIFF_LINES_KEY]).toEqual(['test', 'test2']);
    });
  });

  describe('TOGGLE_DIFF_FILE_RENDERING_MORE', () => {
    it('toggles renderingLines on file', () => {
      const file = { file_path: 'test', renderingLines: false };
      const state = {
        diffFiles: [file],
      };

      mutations[types.TOGGLE_DIFF_FILE_RENDERING_MORE](state, 'test');

      expect(file.renderingLines).toBe(true);

      mutations[types.TOGGLE_DIFF_FILE_RENDERING_MORE](state, 'test');

      expect(file.renderingLines).toBe(false);
    });
  });

  describe('SET_DIFF_FILE_VIEWER', () => {
    it("should update the correct diffFile's viewer property", () => {
      const state = {
        diffFiles: [
          { file_path: 'SearchString', viewer: 'OLD VIEWER' },
          { file_path: 'OtherSearchString' },
          { file_path: 'SomeOtherString' },
        ],
      };

      mutations[types.SET_DIFF_FILE_VIEWER](state, {
        filePath: 'SearchString',
        viewer: 'NEW VIEWER',
      });

      expect(state.diffFiles[0].viewer).toEqual('NEW VIEWER');
      expect(state.diffFiles[1].viewer).not.toBeDefined();
      expect(state.diffFiles[2].viewer).not.toBeDefined();

      mutations[types.SET_DIFF_FILE_VIEWER](state, {
        filePath: 'OtherSearchString',
        viewer: 'NEW VIEWER',
      });

      expect(state.diffFiles[0].viewer).toEqual('NEW VIEWER');
      expect(state.diffFiles[1].viewer).toEqual('NEW VIEWER');
      expect(state.diffFiles[2].viewer).not.toBeDefined();
    });
  });

  describe('SET_SHOW_SUGGEST_POPOVER', () => {
    it('sets showSuggestPopover to false', () => {
      const state = { showSuggestPopover: true };

      mutations[types.SET_SHOW_SUGGEST_POPOVER](state);

      expect(state.showSuggestPopover).toBe(false);
    });
  });

  describe('SET_FILE_BY_FILE', () => {
    it.each`
      value    | opposite
      ${true}  | ${false}
      ${false} | ${true}
    `('sets viewDiffsFileByFile to $value', ({ value, opposite }) => {
      const state = { viewDiffsFileByFile: opposite };

      mutations[types.SET_FILE_BY_FILE](state, value);

      expect(state.viewDiffsFileByFile).toBe(value);
    });
  });

  describe('SET_MR_FILE_REVIEWS', () => {
    it.each`
      newReviews          | oldReviews
      ${{ abc: ['123'] }} | ${{}}
      ${{ abc: [] }}      | ${{ abc: ['123'] }}
      ${{}}               | ${{ abc: ['123'] }}
    `('sets mrReviews to $newReviews', ({ newReviews, oldReviews }) => {
      const state = { mrReviews: oldReviews };

      mutations[types.SET_MR_FILE_REVIEWS](state, newReviews);

      expect(state.mrReviews).toStrictEqual(newReviews);
    });
  });

  describe('TOGGLE_FILE_COMMENT_FORM', () => {
    it('toggles diff files hasCommentForm', () => {
      const state = { diffFiles: [{ file_path: 'path', hasCommentForm: false }] };

      mutations[types.TOGGLE_FILE_COMMENT_FORM](state, 'path');

      expect(state.diffFiles[0].hasCommentForm).toEqual(true);
    });
  });

  describe('SET_FILE_COMMENT_FORM', () => {
    it('toggles diff files hasCommentForm', () => {
      const state = { diffFiles: [{ file_path: 'path', hasCommentForm: false }] };
      const expanded = true;

      mutations[types.SET_FILE_COMMENT_FORM](state, { filePath: 'path', expanded });

      expect(state.diffFiles[0].hasCommentForm).toEqual(expanded);
    });
  });

  describe('ADD_DRAFT_TO_FILE', () => {
    it('adds draft to diff file', () => {
      const state = { diffFiles: [{ file_path: 'path', drafts: [] }] };

      mutations[types.ADD_DRAFT_TO_FILE](state, { filePath: 'path', draft: 'test' });

      expect(state.diffFiles[0].drafts.length).toEqual(1);
      expect(state.diffFiles[0].drafts[0]).toEqual('test');
    });
  });

  describe('SET_FILE_FORCED_OPEN', () => {
    it('sets the forceOpen property of a diff file viewer correctly', () => {
      const state = { diffFiles: [{ file_path: 'abc', viewer: { forceOpen: 'not-a-boolean' } }] };

      mutations[types.SET_FILE_FORCED_OPEN](state, { filePath: 'abc', force: true });

      expect(state.diffFiles[0].viewer.forceOpen).toBe(true);
    });
  });

  describe('TOGGLE_FILE_DISCUSSION_EXPAND', () => {
    const fileHash = 'foo';

    it('expands collapsed discussion', () => {
      const discussion = {
        diff_file: { file_hash: fileHash },
        expandedOnDiff: false,
      };
      const state = {
        diffFiles: [{ file_hash: fileHash, discussions: [discussion] }],
      };

      mutations[types.TOGGLE_FILE_DISCUSSION_EXPAND](state, { discussion });

      expect(state.diffFiles[0].discussions[0].expandedOnDiff).toBe(true);
    });

    it('collapses expanded discussion', () => {
      const discussion = {
        diff_file: { file_hash: fileHash },
        expandedOnDiff: true,
      };
      const state = {
        diffFiles: [{ file_hash: fileHash, discussions: [discussion] }],
      };

      mutations[types.TOGGLE_FILE_DISCUSSION_EXPAND](state, { discussion });

      expect(state.diffFiles[0].discussions[0].expandedOnDiff).toBe(false);
    });
  });

  describe('SET_EXPAND_ALL_DIFF_DISCUSSIONS', () => {
    it('expands all discussions', () => {
      const state = {
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
      };

      mutations[types.SET_EXPAND_ALL_DIFF_DISCUSSIONS](state, true);

      expect(state.diffFiles[0][INLINE_DIFF_LINES_KEY][0].discussionsExpanded).toBe(true);
      expect(state.diffFiles[0].discussions[0].expandedOnDiff).toBe(true);
      expect(state.diffFiles[1].discussions[0].expandedOnDiff).toBe(true);
    });
  });

  describe('SET_LINKED_FILE_HASH', () => {
    it('set linked file hash', () => {
      const state = {};
      const file = getDiffFileMock();

      mutations[types.SET_LINKED_FILE_HASH](state, file.file_hash);

      expect(state.linkedFileHash).toBe(file.file_hash);
    });
  });

  describe('SET_COLLAPSED_STATE_FOR_ALL_FILES', () => {
    it('sets collapsed state for all files', () => {
      const state = {
        diffFiles: [getDiffFileMock(), getDiffFileMock()],
      };

      mutations[types.SET_COLLAPSED_STATE_FOR_ALL_FILES](state, { collapsed: true });

      expect(
        state.diffFiles.every(
          ({ viewer }) => viewer.manuallyCollapsed && !viewer.automaticallyCollapsed,
        ),
      ).toBe(true);
    });
  });
});
