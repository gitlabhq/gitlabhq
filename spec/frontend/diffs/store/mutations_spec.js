import { INLINE_DIFF_VIEW_TYPE, INLINE_DIFF_LINES_KEY } from '~/diffs/constants';
import createState from '~/diffs/store/modules/diff_state';
import * as types from '~/diffs/store/mutation_types';
import mutations from '~/diffs/store/mutations';
import * as utils from '~/diffs/store/utils';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffsStoreMutations', () => {
  describe('SET_BASE_CONFIG', () => {
    it.each`
      prop                    | value
      ${'endpoint'}           | ${'/diffs/endpoint'}
      ${'projectPath'}        | ${'/root/project'}
      ${'endpointUpdateUser'} | ${'/user/preferences'}
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

  describe('SET_BATCH_LOADING', () => {
    it('should set loading state', () => {
      const state = {};

      mutations[types.SET_BATCH_LOADING](state, false);

      expect(state.isBatchLoading).toEqual(false);
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

  describe('SET_DIFF_DATA_BATCH_DATA', () => {
    it('should set diff data batch type properly', () => {
      const state = { diffFiles: [] };
      const diffMock = {
        diff_files: [diffFileMockData],
      };

      mutations[types.SET_DIFF_DATA_BATCH](state, diffMock);

      expect(state.diffFiles[0].renderIt).toEqual(true);
      expect(state.diffFiles[0].collapsed).toEqual(false);
    });
  });

  describe('SET_COVERAGE_DATA', () => {
    it('should set coverage data properly', () => {
      const state = { coverageFiles: {} };
      const coverage = { 'app.js': { 1: 0, 2: 1 } };

      mutations[types.SET_COVERAGE_DATA](state, coverage);

      expect(state.coverageFiles).toEqual(coverage);
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
          { old_line: 1, new_line: 1, line_code: 'ff9200_1_1', discussions: [], hasForm: false },
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

  describe('SET_SHOW_TREE_LIST', () => {
    it('sets showTreeList', () => {
      const state = createState();

      mutations[types.SET_SHOW_TREE_LIST](state, true);

      expect(state.showTreeList).toBe(true, 'Failed to toggle showTreeList to true');
    });
  });

  describe('VIEW_DIFF_FILE', () => {
    it('updates currentDiffFileId', () => {
      const state = createState();

      mutations[types.VIEW_DIFF_FILE](state, 'somefileid');

      expect(state.currentDiffFileId).toBe('somefileid');
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
});
