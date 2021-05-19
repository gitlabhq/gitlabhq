import { shallowMount } from '@vue/test-utils';
import DiffGutterAvatars from '~/diffs/components/diff_gutter_avatars.vue';
import { mapInline } from '~/diffs/components/diff_row_utils';
import InlineDiffTableRow from '~/diffs/components/inline_diff_table_row.vue';
import { createStore } from '~/mr_notes/stores';
import { findInteropAttributes } from '../find_interop_attributes';
import discussionsMockData from '../mock_data/diff_discussions';
import diffFileMockData from '../mock_data/diff_file';

const TEST_USER_ID = 'abc123';
const TEST_USER = { id: TEST_USER_ID };

describe('InlineDiffTableRow', () => {
  let wrapper;
  let store;
  const mockDiffContent = {
    diffFile: diffFileMockData,
    shouldRenderDraftRow: jest.fn(),
    hasParallelDraftLeft: jest.fn(),
    hasParallelDraftRight: jest.fn(),
    draftForLine: jest.fn(),
  };

  const applyMap = mapInline(mockDiffContent);
  const thisLine = applyMap(diffFileMockData.highlighted_diff_lines[0]);

  const createComponent = (props = {}, propsStore = store) => {
    wrapper = shallowMount(InlineDiffTableRow, {
      store: propsStore,
      propsData: {
        line: thisLine,
        fileHash: diffFileMockData.file_hash,
        filePath: diffFileMockData.file_path,
        contextLinesPath: 'contextLinesPath',
        isHighlighted: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    store.state.notes.userData = TEST_USER;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not add hll class to line content when line does not match highlighted row', () => {
    createComponent();
    expect(wrapper.find('.line_content').classes('hll')).toBe(false);
  });

  it('adds hll class to lineContent when line is the highlighted row', () => {
    store.state.diffs.highlightedRow = thisLine.line_code;
    createComponent({}, store);
    expect(wrapper.find('.line_content').classes('hll')).toBe(true);
  });

  it('adds hll class to lineContent when line is part of a multiline comment', () => {
    createComponent({ isCommented: true });
    expect(wrapper.find('.line_content').classes('hll')).toBe(true);
  });

  describe('sets coverage title and class', () => {
    it('for lines with coverage', () => {
      const name = diffFileMockData.file_path;
      const line = thisLine.new_line;

      store.state.diffs.coverageFiles = { files: { [name]: { [line]: 5 } } };
      createComponent({}, store);
      const coverage = wrapper.find('.line-coverage');

      expect(coverage.attributes('title')).toContain('Test coverage: 5 hits');
      expect(coverage.classes('coverage')).toBe(true);
    });

    it('for lines without coverage', () => {
      const name = diffFileMockData.file_path;
      const line = thisLine.new_line;

      store.state.diffs.coverageFiles = { files: { [name]: { [line]: 0 } } };
      createComponent({}, store);
      const coverage = wrapper.find('.line-coverage');

      expect(coverage.attributes('title')).toContain('No test coverage');
      expect(coverage.classes('no-coverage')).toBe(true);
    });

    it('for unknown lines', () => {
      store.state.diffs.coverageFiles = {};
      createComponent({}, store);

      const coverage = wrapper.find('.line-coverage');

      expect(coverage.attributes('title')).toBeUndefined();
      expect(coverage.classes('coverage')).toBe(false);
      expect(coverage.classes('no-coverage')).toBe(false);
    });
  });

  describe('Table Cells', () => {
    const findNewTd = () => wrapper.find({ ref: 'newTd' });
    const findOldTd = () => wrapper.find({ ref: 'oldTd' });

    describe('td', () => {
      it('highlights when isHighlighted true', () => {
        store.state.diffs.highlightedRow = thisLine.line_code;
        createComponent({}, store);

        expect(findNewTd().classes()).toContain('hll');
        expect(findOldTd().classes()).toContain('hll');
      });

      it('does not highlight when isHighlighted false', () => {
        createComponent();

        expect(findNewTd().classes()).not.toContain('hll');
        expect(findOldTd().classes()).not.toContain('hll');
      });
    });

    describe('comment button', () => {
      const findNoteButton = () => wrapper.find({ ref: 'addDiffNoteButton' });

      it.each`
        userData     | expectation
        ${TEST_USER} | ${true}
        ${null}      | ${false}
      `('exists is $expectation - with userData ($userData)', ({ userData, expectation }) => {
        store.state.notes.userData = userData;
        createComponent({}, store);

        expect(findNoteButton().exists()).toBe(expectation);
      });

      it.each`
        isHover  | line                                                       | expectation
        ${true}  | ${{ ...thisLine, discussions: [] }}                        | ${true}
        ${false} | ${{ ...thisLine, discussions: [] }}                        | ${false}
        ${true}  | ${{ ...thisLine, type: 'context', discussions: [] }}       | ${false}
        ${true}  | ${{ ...thisLine, type: 'old-nonewline', discussions: [] }} | ${false}
        ${true}  | ${{ ...thisLine, discussions: [{}] }}                      | ${false}
      `('visible is $expectation - line ($line)', ({ isHover, line, expectation }) => {
        createComponent({ line: applyMap(line) });
        wrapper.setData({ isHover });

        return wrapper.vm.$nextTick().then(() => {
          expect(findNoteButton().isVisible()).toBe(expectation);
        });
      });

      it.each`
        disabled      | commentsDisabled
        ${'disabled'} | ${true}
        ${undefined}  | ${false}
      `(
        'has attribute disabled=$disabled when the outer component has prop commentsDisabled=$commentsDisabled',
        ({ disabled, commentsDisabled }) => {
          createComponent({
            line: applyMap({ ...thisLine, commentsDisabled }),
          });

          wrapper.setData({ isHover: true });

          return wrapper.vm.$nextTick().then(() => {
            expect(findNoteButton().attributes('disabled')).toBe(disabled);
          });
        },
      );

      const symlinkishFileTooltip =
        'Commenting on symbolic links that replace or are replaced by files is currently not supported.';
      const realishFileTooltip =
        'Commenting on files that replace or are replaced by symbolic links is currently not supported.';
      const otherFileTooltip = 'Add a comment to this line';
      const findTooltip = () => wrapper.find({ ref: 'addNoteTooltip' });

      it.each`
        tooltip                  | commentsDisabled
        ${symlinkishFileTooltip} | ${{ wasSymbolic: true }}
        ${symlinkishFileTooltip} | ${{ isSymbolic: true }}
        ${realishFileTooltip}    | ${{ wasReal: true }}
        ${realishFileTooltip}    | ${{ isReal: true }}
        ${otherFileTooltip}      | ${false}
      `(
        'has the correct tooltip when commentsDisabled=$commentsDisabled',
        ({ tooltip, commentsDisabled }) => {
          createComponent({
            line: applyMap({ ...thisLine, commentsDisabled }),
          });

          wrapper.setData({ isHover: true });

          return wrapper.vm.$nextTick().then(() => {
            expect(findTooltip().attributes('title')).toBe(tooltip);
          });
        },
      );
    });

    describe('line number', () => {
      const findLineNumberOld = () => wrapper.find({ ref: 'lineNumberRefOld' });
      const findLineNumberNew = () => wrapper.find({ ref: 'lineNumberRefNew' });

      it('renders line numbers in correct cells', () => {
        createComponent();

        expect(findLineNumberOld().exists()).toBe(false);
        expect(findLineNumberNew().exists()).toBe(true);
      });

      describe('with lineNumber prop', () => {
        const TEST_LINE_CODE = 'LC_42';
        const TEST_LINE_NUMBER = 1;

        describe.each`
          lineProps                                                                                     | findLineNumber       | expectedHref            | expectedClickArg
          ${{ line_code: TEST_LINE_CODE, old_line: TEST_LINE_NUMBER }}                                  | ${findLineNumberOld} | ${`#${TEST_LINE_CODE}`} | ${TEST_LINE_CODE}
          ${{ line_code: undefined, old_line: TEST_LINE_NUMBER }}                                       | ${findLineNumberOld} | ${'#'}                  | ${undefined}
          ${{ line_code: undefined, left: { line_code: TEST_LINE_CODE }, old_line: TEST_LINE_NUMBER }}  | ${findLineNumberOld} | ${'#'}                  | ${TEST_LINE_CODE}
          ${{ line_code: undefined, right: { line_code: TEST_LINE_CODE }, new_line: TEST_LINE_NUMBER }} | ${findLineNumberNew} | ${'#'}                  | ${TEST_LINE_CODE}
        `(
          'with line ($lineProps)',
          ({ lineProps, findLineNumber, expectedHref, expectedClickArg }) => {
            beforeEach(() => {
              jest.spyOn(store, 'dispatch').mockImplementation();
              createComponent({
                line: applyMap({ ...thisLine, ...lineProps }),
              });
            });

            it('renders', () => {
              expect(findLineNumber().exists()).toBe(true);
              expect(findLineNumber().attributes()).toEqual({
                href: expectedHref,
                'data-linenumber': TEST_LINE_NUMBER.toString(),
              });
            });

            it('on click, dispatches setHighlightedRow', () => {
              expect(store.dispatch).toHaveBeenCalledTimes(1);

              findLineNumber().trigger('click');

              expect(store.dispatch).toHaveBeenCalledWith(
                'diffs/setHighlightedRow',
                expectedClickArg,
              );
              expect(store.dispatch).toHaveBeenCalledTimes(2);
            });
          },
        );
      });
    });

    describe('diff-gutter-avatars', () => {
      const TEST_LINE_CODE = 'LC_42';
      const TEST_FILE_HASH = diffFileMockData.file_hash;
      const findAvatars = () => wrapper.find(DiffGutterAvatars);
      let line;

      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockImplementation();

        line = {
          line_code: TEST_LINE_CODE,
          type: 'new',
          old_line: null,
          new_line: 1,
          discussions: [{ ...discussionsMockData }],
          discussionsExpanded: true,
          text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
          rich_text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
          meta_data: null,
        };
      });

      describe('with showCommentButton', () => {
        it('renders if line has discussions', () => {
          createComponent({ line: applyMap(line) });

          expect(findAvatars().props()).toEqual({
            discussions: line.discussions,
            discussionsExpanded: line.discussionsExpanded,
          });
        });

        it('does notrender if line has no discussions', () => {
          line.discussions = [];
          createComponent({ line: applyMap(line) });

          expect(findAvatars().exists()).toEqual(false);
        });

        it('toggles line discussion', () => {
          createComponent({ line: applyMap(line) });

          expect(store.dispatch).toHaveBeenCalledTimes(1);

          findAvatars().vm.$emit('toggleLineDiscussions');

          expect(store.dispatch).toHaveBeenCalledWith('diffs/toggleLineDiscussions', {
            lineCode: TEST_LINE_CODE,
            fileHash: TEST_FILE_HASH,
            expanded: !line.discussionsExpanded,
          });
        });
      });
    });
  });

  describe('interoperability', () => {
    it.each`
      desc               | line                                                      | expectation
      ${'with type old'} | ${{ ...thisLine, type: 'old', old_line: 3, new_line: 5 }} | ${{ type: 'old', line: '3', oldLine: '3', newLine: '5' }}
      ${'with type new'} | ${{ ...thisLine, type: 'new', old_line: 3, new_line: 5 }} | ${{ type: 'new', line: '5', oldLine: '3', newLine: '5' }}
    `('$desc, sets interop data attributes', ({ line, expectation }) => {
      createComponent({ line });

      expect(findInteropAttributes(wrapper)).toEqual(expectation);
    });
  });
});
