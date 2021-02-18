import { getByText } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import DiffExpansionCell from '~/diffs/components/diff_expansion_cell.vue';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { getPreviousLineIndex } from '~/diffs/store/utils';
import { createStore } from '~/mr_notes/stores';
import diffFileMockData from '../mock_data/diff_file';

const EXPAND_UP_CLASS = '.js-unfold';
const EXPAND_DOWN_CLASS = '.js-unfold-down';
const lineSources = {
  [INLINE_DIFF_VIEW_TYPE]: 'highlighted_diff_lines',
};
const lineHandlers = {
  [INLINE_DIFF_VIEW_TYPE]: (line) => line,
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

  beforeEach(() => {
    mockFile = cloneDeep(diffFileMockData);
    mockLine = getLine(mockFile, INLINE_DIFF_VIEW_TYPE, 8);
    store = createStore();
    store.state.diffs.diffFiles = [mockFile];
    jest.spyOn(store, 'dispatch').mockReturnValue(Promise.resolve());
  });

  const createComponent = (options = {}) => {
    const defaults = {
      fileHash: mockFile.file_hash,
      contextLinesPath: 'contextLinesPath',
      line: mockLine,
      isTop: false,
      isBottom: false,
    };
    const propsData = { ...defaults, ...options };

    return mount(DiffExpansionCell, { store, propsData });
  };

  const findExpandUp = (wrapper) => wrapper.find(EXPAND_UP_CLASS);
  const findExpandDown = (wrapper) => wrapper.find(EXPAND_DOWN_CLASS);
  const findExpandAll = ({ element }) => getByText(element, 'Show all unchanged lines');

  describe('top row', () => {
    it('should have "expand up" and "show all" option', () => {
      const wrapper = createComponent({
        isTop: true,
      });

      expect(findExpandUp(wrapper).exists()).toBe(true);
      expect(findExpandDown(wrapper).exists()).toBe(false);
      expect(findExpandAll(wrapper)).not.toBe(null);
    });
  });

  describe('middle row', () => {
    it('should have "expand down", "show all", "expand up" option', () => {
      const wrapper = createComponent();

      expect(findExpandUp(wrapper).exists()).toBe(true);
      expect(findExpandDown(wrapper).exists()).toBe(true);
      expect(findExpandAll(wrapper)).not.toBe(null);
    });
  });

  describe('bottom row', () => {
    it('should have "expand down" and "show all" option', () => {
      const wrapper = createComponent({
        isBottom: true,
      });

      expect(findExpandUp(wrapper).exists()).toBe(false);
      expect(findExpandDown(wrapper).exists()).toBe(true);
      expect(findExpandAll(wrapper)).not.toBe(null);
    });
  });

  describe('any row', () => {
    [
      { diffViewType: INLINE_DIFF_VIEW_TYPE, lineIndex: 8, file: { parallel_diff_lines: [] } },
    ].forEach(({ diffViewType, file, lineIndex }) => {
      describe(`with diffViewType (${diffViewType})`, () => {
        beforeEach(() => {
          mockLine = getLine(mockFile, diffViewType, lineIndex);
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

          const wrapper = createComponent();

          findExpandAll(wrapper).click();

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

          const wrapper = createComponent();

          findExpandUp(wrapper).trigger('click');

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
          mockFile[lineSources[diffViewType]][lineIndex + 1] = cloneDeep(
            mockFile[lineSources[diffViewType]][lineIndex],
          );
          const nextLine = getLine(mockFile, diffViewType, lineIndex + 1);

          nextLine.meta_data.old_pos = 300;
          nextLine.meta_data.new_pos = 300;
          mockLine.meta_data.old_pos = 200;
          mockLine.meta_data.new_pos = 200;

          const wrapper = createComponent();

          findExpandDown(wrapper).trigger('click');

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
