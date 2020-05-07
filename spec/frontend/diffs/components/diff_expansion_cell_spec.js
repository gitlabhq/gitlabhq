import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import DiffExpansionCell from '~/diffs/components/diff_expansion_cell.vue';
import { getPreviousLineIndex } from '~/diffs/store/utils';
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '~/diffs/constants';
import diffFileMockData from '../mock_data/diff_file';

const EXPAND_UP_CLASS = '.js-unfold';
const EXPAND_DOWN_CLASS = '.js-unfold-down';
const EXPAND_ALL_CLASS = '.js-unfold-all';
const LINE_TO_USE = 5;
const lineSources = {
  [INLINE_DIFF_VIEW_TYPE]: 'highlighted_diff_lines',
  [PARALLEL_DIFF_VIEW_TYPE]: 'parallel_diff_lines',
};
const lineHandlers = {
  [INLINE_DIFF_VIEW_TYPE]: line => line,
  [PARALLEL_DIFF_VIEW_TYPE]: line => line.right || line.left,
};

function makeLoadMoreLinesPayload({
  sinceLine,
  toLine,
  oldLineNumber,
  diffViewType,
  fileHash,
  nextLineNumbers = {},
  unfold = false,
  bottom = false,
  isExpandDown = false,
}) {
  return {
    endpoint: 'contextLinesPath',
    params: {
      since: sinceLine,
      to: toLine,
      offset: toLine + 1 - oldLineNumber,
      view: diffViewType,
      unfold,
      bottom,
    },
    lineNumbers: {
      oldLineNumber,
      newLineNumber: toLine + 1,
    },
    nextLineNumbers,
    fileHash,
    isExpandDown,
  };
}

function getLine(file, type, index) {
  const source = lineSources[type];
  const handler = lineHandlers[type];

  return handler(file[source][index]);
}

describe('DiffExpansionCell', () => {
  let mockFile;
  let mockLine;
  let store;
  let vm;

  beforeEach(() => {
    mockFile = cloneDeep(diffFileMockData);
    mockLine = getLine(mockFile, INLINE_DIFF_VIEW_TYPE, LINE_TO_USE);
    store = createStore();
    store.state.diffs.diffFiles = [mockFile];
    jest.spyOn(store, 'dispatch').mockReturnValue(Promise.resolve());
  });

  const createComponent = (options = {}) => {
    const cmp = Vue.extend(DiffExpansionCell);
    const defaults = {
      fileHash: mockFile.file_hash,
      contextLinesPath: 'contextLinesPath',
      line: mockLine,
      isTop: false,
      isBottom: false,
    };
    const props = { ...defaults, ...options };

    vm = createComponentWithStore(cmp, store, props).$mount();
  };

  const findExpandUp = () => vm.$el.querySelector(EXPAND_UP_CLASS);
  const findExpandDown = () => vm.$el.querySelector(EXPAND_DOWN_CLASS);
  const findExpandAll = () => vm.$el.querySelector(EXPAND_ALL_CLASS);

  describe('top row', () => {
    it('should have "expand up" and "show all" option', () => {
      createComponent({
        isTop: true,
      });

      expect(findExpandUp()).not.toBe(null);
      expect(findExpandDown()).toBe(null);
      expect(findExpandAll()).not.toBe(null);
    });
  });

  describe('middle row', () => {
    it('should have "expand down", "show all", "expand up" option', () => {
      createComponent();

      expect(findExpandUp()).not.toBe(null);
      expect(findExpandDown()).not.toBe(null);
      expect(findExpandAll()).not.toBe(null);
    });
  });

  describe('bottom row', () => {
    it('should have "expand down" and "show all" option', () => {
      createComponent({
        isBottom: true,
      });

      expect(findExpandUp()).toBe(null);
      expect(findExpandDown()).not.toBe(null);
      expect(findExpandAll()).not.toBe(null);
    });
  });

  describe('any row', () => {
    [
      { diffViewType: INLINE_DIFF_VIEW_TYPE, file: { parallel_diff_lines: [] } },
      { diffViewType: PARALLEL_DIFF_VIEW_TYPE, file: { highlighted_diff_lines: [] } },
    ].forEach(({ diffViewType, file }) => {
      describe(`with diffViewType (${diffViewType})`, () => {
        beforeEach(() => {
          mockLine = getLine(mockFile, diffViewType, LINE_TO_USE);
          store.state.diffs.diffFiles = [{ ...mockFile, ...file }];
          store.state.diffs.diffViewType = diffViewType;
        });

        it('does not initially dispatch anything', () => {
          expect(store.dispatch).not.toHaveBeenCalled();
        });

        it('on expand all clicked, dispatch loadMoreLines', () => {
          const oldLineNumber = mockLine.meta_data.old_pos;
          const newLineNumber = mockLine.meta_data.new_pos;
          const previousIndex = getPreviousLineIndex(diffViewType, mockFile, {
            oldLineNumber,
            newLineNumber,
          });

          createComponent();

          findExpandAll().click();

          expect(store.dispatch).toHaveBeenCalledWith(
            'diffs/loadMoreLines',
            makeLoadMoreLinesPayload({
              fileHash: mockFile.file_hash,
              toLine: newLineNumber - 1,
              sinceLine: previousIndex,
              oldLineNumber,
              diffViewType,
            }),
          );
        });

        it('on expand up clicked, dispatch loadMoreLines', () => {
          mockLine.meta_data.old_pos = 200;
          mockLine.meta_data.new_pos = 200;

          const oldLineNumber = mockLine.meta_data.old_pos;
          const newLineNumber = mockLine.meta_data.new_pos;

          createComponent();

          findExpandUp().click();

          expect(store.dispatch).toHaveBeenCalledWith(
            'diffs/loadMoreLines',
            makeLoadMoreLinesPayload({
              fileHash: mockFile.file_hash,
              toLine: newLineNumber - 1,
              sinceLine: 179,
              oldLineNumber,
              diffViewType,
              unfold: true,
            }),
          );
        });

        it('on expand down clicked, dispatch loadMoreLines', () => {
          mockFile[lineSources[diffViewType]][LINE_TO_USE + 1] = cloneDeep(
            mockFile[lineSources[diffViewType]][LINE_TO_USE],
          );
          const nextLine = getLine(mockFile, diffViewType, LINE_TO_USE + 1);

          nextLine.meta_data.old_pos = 300;
          nextLine.meta_data.new_pos = 300;
          mockLine.meta_data.old_pos = 200;
          mockLine.meta_data.new_pos = 200;

          createComponent();

          findExpandDown().click();

          expect(store.dispatch).toHaveBeenCalledWith('diffs/loadMoreLines', {
            endpoint: 'contextLinesPath',
            params: {
              since: 1,
              to: 21, // the load amount, plus 1 line
              offset: 0,
              view: diffViewType,
              unfold: true,
              bottom: true,
            },
            lineNumbers: {
              // when expanding down, these are based on the previous line, 0, in this case
              oldLineNumber: 0,
              newLineNumber: 0,
            },
            nextLineNumbers: { old_line: 200, new_line: 200 },
            fileHash: mockFile.file_hash,
            isExpandDown: true,
          });
        });
      });
    });
  });
});
