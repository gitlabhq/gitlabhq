import { mount } from '@vue/test-utils';
import DiffExpansionCell from '~/diffs/components/diff_expansion_cell.vue';
import { INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import { getPreviousLineIndex } from '~/diffs/store/utils';
import { createStore } from '~/mr_notes/stores';
import { getDiffFileMock } from '../mock_data/diff_file';

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
  fileHash,
  nextLineNumbers = {},
  unfold = false,
  bottom = false,
  isExpandDown = false,
}) {
  return {
    endpoint: getDiffFileMock().context_lines_path,
    params: {
      since: sinceLine,
      to: toLine,
      offset: toLine + 1 - oldLineNumber,
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
    mockFile = getDiffFileMock();
    mockLine = getLine(mockFile, INLINE_DIFF_VIEW_TYPE, 8);
    store = createStore();
    store.state.diffs.diffFiles = [mockFile];
    jest.spyOn(store, 'dispatch').mockReturnValue(Promise.resolve());
  });

  const createComponent = (options = {}) => {
    const defaults = {
      fileHash: mockFile.file_hash,
      line: mockLine,
      isTop: false,
      isBottom: false,
      file: mockFile,
      inline: true,
    };
    const propsData = { ...defaults, ...options };

    return mount(DiffExpansionCell, { store, propsData });
  };

  const findExpandUp = (wrapper) => wrapper.find(EXPAND_UP_CLASS);
  const findExpandDown = (wrapper) => wrapper.find(EXPAND_DOWN_CLASS);
  const findExpandAll = (wrapper) => wrapper.find('.js-unfold-all');

  describe('top row', () => {
    it('should have "expand up" and "show all" option', () => {
      const wrapper = createComponent({
        isTop: true,
      });

      expect(findExpandUp(wrapper).exists()).toBe(true);
      expect(findExpandUp(wrapper).attributes('disabled')).not.toBeDefined();
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

      expect(findExpandDown(wrapper).exists()).toBe(true);
      expect(findExpandDown(wrapper).attributes('disabled')).not.toBeDefined();
      expect(findExpandAll(wrapper)).not.toBe(null);
    });
  });

  describe('any row', () => {
    [{ diffViewType: INLINE_DIFF_VIEW_TYPE, lineIndex: 8, file: getDiffFileMock() }].forEach(
      ({ diffViewType, file, lineIndex }) => {
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
            const previousIndex = getPreviousLineIndex(mockFile, {
              oldLineNumber,
              newLineNumber,
            });

            const wrapper = createComponent({ file, lineCountBetween: 10 });

            findExpandAll(wrapper).trigger('click');

            expect(store.dispatch).toHaveBeenCalledWith(
              'diffs/loadMoreLines',
              makeLoadMoreLinesPayload({
                fileHash: mockFile.file_hash,
                toLine: newLineNumber - 1,
                sinceLine: previousIndex,
                oldLineNumber,
              }),
            );
          });

          it('on expand up clicked, dispatch loadMoreLines', () => {
            mockLine.meta_data.old_pos = 200;
            mockLine.meta_data.new_pos = 200;

            const oldLineNumber = mockLine.meta_data.old_pos;
            const newLineNumber = mockLine.meta_data.new_pos;

            const wrapper = createComponent({ file });

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
            mockFile[lineSources[diffViewType]][lineIndex + 1] =
              getDiffFileMock()[lineSources[diffViewType]][lineIndex];
            const nextLine = getLine(mockFile, diffViewType, lineIndex + 1);

            nextLine.meta_data.old_pos = 300;
            nextLine.meta_data.new_pos = 300;
            mockLine.meta_data.old_pos = 200;
            mockLine.meta_data.new_pos = 200;

            const wrapper = createComponent({ file });

            findExpandDown(wrapper).trigger('click');

            expect(store.dispatch).toHaveBeenCalledWith('diffs/loadMoreLines', {
              endpoint: mockFile.context_lines_path,
              params: {
                since: 1,
                to: 21, // the load amount, plus 1 line
                offset: 0,
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
      },
    );
  });
});
