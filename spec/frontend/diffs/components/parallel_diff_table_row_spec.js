import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import DiffGutterAvatars from '~/diffs/components/diff_gutter_avatars.vue';
import { mapParallel } from '~/diffs/components/diff_row_utils';
import ParallelDiffTableRow from '~/diffs/components/parallel_diff_table_row.vue';
import { createStore } from '~/mr_notes/stores';
import { findInteropAttributes } from '../find_interop_attributes';
import discussionsMockData from '../mock_data/diff_discussions';
import diffFileMockData from '../mock_data/diff_file';

describe('ParallelDiffTableRow', () => {
  const mockDiffContent = {
    diffFile: diffFileMockData,
    shouldRenderDraftRow: jest.fn(),
    hasParallelDraftLeft: jest.fn(),
    hasParallelDraftRight: jest.fn(),
    draftForLine: jest.fn(),
  };

  const applyMap = mapParallel(mockDiffContent);

  describe('when one side is empty', () => {
    let wrapper;
    let vm;
    const thisLine = diffFileMockData.parallel_diff_lines[0];
    const rightLine = diffFileMockData.parallel_diff_lines[0].right;

    beforeEach(() => {
      wrapper = shallowMount(ParallelDiffTableRow, {
        store: createStore(),
        propsData: {
          line: applyMap(thisLine),
          fileHash: diffFileMockData.file_hash,
          filePath: diffFileMockData.file_path,
          contextLinesPath: 'contextLinesPath',
          isHighlighted: false,
        },
      });

      vm = wrapper.vm;
    });

    it('does not highlight non empty line content when line does not match highlighted row', (done) => {
      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).not.toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    it('highlights nonempty line content when line is the highlighted row', (done) => {
      vm.$nextTick()
        .then(() => {
          vm.$store.state.diffs.highlightedRow = rightLine.line_code;

          return vm.$nextTick();
        })
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    it('highlights nonempty line content when line is part of a multiline comment', () => {
      wrapper.setProps({ isCommented: true });
      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelector('.line_content.right-side').classList).toContain('hll');
      });
    });
  });

  describe('when both sides have content', () => {
    let vm;
    const thisLine = diffFileMockData.parallel_diff_lines[2];
    const rightLine = diffFileMockData.parallel_diff_lines[2].right;

    beforeEach(() => {
      vm = createComponentWithStore(Vue.extend(ParallelDiffTableRow), createStore(), {
        line: applyMap(thisLine),
        fileHash: diffFileMockData.file_hash,
        filePath: diffFileMockData.file_path,
        contextLinesPath: 'contextLinesPath',
        isHighlighted: false,
      }).$mount();
    });

    it('does not highlight  either line when line does not match highlighted row', (done) => {
      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).not.toContain('hll');
          expect(vm.$el.querySelector('.line_content.left-side').classList).not.toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    it('adds hll class to lineContent when line is the highlighted row', (done) => {
      vm.$nextTick()
        .then(() => {
          vm.$store.state.diffs.highlightedRow = rightLine.line_code;

          return vm.$nextTick();
        })
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).toContain('hll');
          expect(vm.$el.querySelector('.line_content.left-side').classList).toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    describe('sets coverage title and class', () => {
      it('for lines with coverage', (done) => {
        vm.$nextTick()
          .then(() => {
            const name = diffFileMockData.file_path;
            const line = rightLine.new_line;

            vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 5 } } };

            return vm.$nextTick();
          })
          .then(() => {
            const coverage = vm.$el.querySelector('.line-coverage.right-side');

            expect(coverage.title).toContain('Test coverage: 5 hits');
            expect(coverage.classList).toContain('coverage');
          })
          .then(done)
          .catch(done.fail);
      });

      it('for lines without coverage', (done) => {
        vm.$nextTick()
          .then(() => {
            const name = diffFileMockData.file_path;
            const line = rightLine.new_line;

            vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 0 } } };

            return vm.$nextTick();
          })
          .then(() => {
            const coverage = vm.$el.querySelector('.line-coverage.right-side');

            expect(coverage.title).toContain('No test coverage');
            expect(coverage.classList).toContain('no-coverage');
          })
          .then(done)
          .catch(done.fail);
      });

      it('for unknown lines', (done) => {
        vm.$nextTick()
          .then(() => {
            vm.$store.state.diffs.coverageFiles = {};

            return vm.$nextTick();
          })
          .then(() => {
            const coverage = vm.$el.querySelector('.line-coverage.right-side');

            expect(coverage.title).not.toContain('Coverage');
            expect(coverage.classList).not.toContain('coverage');
            expect(coverage.classList).not.toContain('no-coverage');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('Table Cells', () => {
    let wrapper;
    let store;
    let thisLine;
    const TEST_USER_ID = 'abc123';
    const TEST_USER = { id: TEST_USER_ID };

    const createComponent = (props = {}, propsStore = store, data = {}) => {
      wrapper = shallowMount(ParallelDiffTableRow, {
        store: propsStore,
        propsData: {
          line: thisLine,
          fileHash: diffFileMockData.file_hash,
          filePath: diffFileMockData.file_path,
          contextLinesPath: 'contextLinesPath',
          isHighlighted: false,
          ...props,
        },
        data() {
          return data;
        },
      });
    };

    beforeEach(() => {
      // eslint-disable-next-line prefer-destructuring
      thisLine = diffFileMockData.parallel_diff_lines[2];
      store = createStore();
      store.state.notes.userData = TEST_USER;
    });

    afterEach(() => {
      wrapper.destroy();
    });

    const findNewTd = () => wrapper.find({ ref: 'newTd' });
    const findOldTd = () => wrapper.find({ ref: 'oldTd' });

    describe('td', () => {
      it('highlights when isHighlighted true', () => {
        store.state.diffs.highlightedRow = thisLine.left.line_code;
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
      const findNoteButton = () => wrapper.find({ ref: 'addDiffNoteButtonLeft' });

      it.each`
        hover    | line                        | userData     | expectation
        ${true}  | ${{}}                       | ${TEST_USER} | ${true}
        ${true}  | ${{ line: { left: null } }} | ${TEST_USER} | ${false}
        ${true}  | ${{}}                       | ${null}      | ${false}
        ${false} | ${{}}                       | ${TEST_USER} | ${false}
      `(
        'exists is $expectation - with userData ($userData)',
        async ({ hover, line, userData, expectation }) => {
          store.state.notes.userData = userData;
          createComponent(line, store);
          if (hover) await wrapper.find('.line_holder').trigger('mouseover');

          expect(findNoteButton().exists()).toBe(expectation);
        },
      );

      it.each`
        line                                                                 | expectation
        ${{ ...thisLine, left: { discussions: [] } }}                        | ${true}
        ${{ ...thisLine, left: { type: 'context', discussions: [] } }}       | ${false}
        ${{ ...thisLine, left: { type: 'old-nonewline', discussions: [] } }} | ${false}
        ${{ ...thisLine, left: { discussions: [{}] } }}                      | ${false}
      `('visible is $expectation - line ($line)', async ({ line, expectation }) => {
        createComponent({ line: applyMap(line) }, store, {
          isLeftHover: true,
          isCommentButtonRendered: true,
        });

        expect(findNoteButton().isVisible()).toBe(expectation);
      });

      it.each`
        disabled      | commentsDisabled
        ${'disabled'} | ${true}
        ${undefined}  | ${false}
      `(
        'has attribute disabled=$disabled when the outer component has prop commentsDisabled=$commentsDisabled',
        ({ disabled, commentsDisabled }) => {
          thisLine.left.commentsDisabled = commentsDisabled;
          createComponent({ line: { ...thisLine } }, store, {
            isLeftHover: true,
            isCommentButtonRendered: true,
          });

          expect(findNoteButton().attributes('disabled')).toBe(disabled);
        },
      );

      const symlinkishFileTooltip =
        'Commenting on symbolic links that replace or are replaced by files is currently not supported.';
      const realishFileTooltip =
        'Commenting on files that replace or are replaced by symbolic links is currently not supported.';
      const otherFileTooltip = 'Add a comment to this line';
      const findTooltip = () => wrapper.find({ ref: 'addNoteTooltipLeft' });

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
          thisLine.left.commentsDisabled = commentsDisabled;
          createComponent({ line: { ...thisLine } }, store, {
            isLeftHover: true,
            isCommentButtonRendered: true,
          });

          expect(findTooltip().attributes('title')).toBe(tooltip);
        },
      );
    });

    describe('line number', () => {
      const findLineNumberOld = () => wrapper.find({ ref: 'lineNumberRefOld' });
      const findLineNumberNew = () => wrapper.find({ ref: 'lineNumberRefNew' });

      it('renders line numbers in correct cells', () => {
        createComponent();

        expect(findLineNumberOld().exists()).toBe(true);
        expect(findLineNumberNew().exists()).toBe(true);
      });

      describe('with lineNumber prop', () => {
        const TEST_LINE_CODE = 'LC_42';
        const TEST_LINE_NUMBER = 1;

        describe.each`
          lineProps                                                    | findLineNumber       | expectedHref            | expectedClickArg
          ${{ line_code: TEST_LINE_CODE, old_line: TEST_LINE_NUMBER }} | ${findLineNumberOld} | ${`#${TEST_LINE_CODE}`} | ${TEST_LINE_CODE}
          ${{ line_code: undefined, old_line: TEST_LINE_NUMBER }}      | ${findLineNumberOld} | ${'#'}                  | ${undefined}
        `(
          'with line ($lineProps)',
          ({ lineProps, findLineNumber, expectedHref, expectedClickArg }) => {
            beforeEach(() => {
              jest.spyOn(store, 'dispatch').mockImplementation();
              Object.assign(thisLine.left, lineProps);
              Object.assign(thisLine.right, lineProps);
              createComponent({
                line: applyMap({ ...thisLine }),
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

        line = applyMap({
          left: {
            line_code: TEST_LINE_CODE,
            type: 'new',
            old_line: null,
            new_line: 1,
            discussions: [{ ...discussionsMockData }],
            discussionsExpanded: true,
            text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
            rich_text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
            meta_data: null,
          },
        });
      });

      describe('with showCommentButton', () => {
        it('renders if line has discussions', () => {
          createComponent({ line });

          expect(findAvatars().props()).toEqual({
            discussions: line.left.discussions,
            discussionsExpanded: line.left.discussionsExpanded,
          });
        });

        it('does notrender if line has no discussions', () => {
          line.left.discussions = [];
          createComponent({ line: applyMap(line) });

          expect(findAvatars().exists()).toEqual(false);
        });

        it('toggles line discussion', () => {
          createComponent({ line });

          expect(store.dispatch).toHaveBeenCalledTimes(1);

          findAvatars().vm.$emit('toggleLineDiscussions');

          expect(store.dispatch).toHaveBeenCalledWith('diffs/toggleLineDiscussions', {
            lineCode: TEST_LINE_CODE,
            fileHash: TEST_FILE_HASH,
            expanded: !line.left.discussionsExpanded,
          });
        });
      });
    });

    describe('interoperability', () => {
      beforeEach(() => {
        createComponent();
      });

      it('adds old side interoperability data attributes', () => {
        expect(findInteropAttributes(wrapper, '.line_content.left-side')).toEqual({
          type: 'old',
          line: thisLine.left.old_line.toString(),
          oldLine: thisLine.left.old_line.toString(),
        });
      });

      it('adds new side interoperability data attributes', () => {
        expect(findInteropAttributes(wrapper, '.line_content.right-side')).toEqual({
          type: 'new',
          line: thisLine.right.new_line.toString(),
          newLine: thisLine.right.new_line.toString(),
        });
      });
    });
  });
});
