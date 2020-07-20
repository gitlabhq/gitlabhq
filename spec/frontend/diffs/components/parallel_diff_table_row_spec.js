import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import ParallelDiffTableRow from '~/diffs/components/parallel_diff_table_row.vue';
import diffFileMockData from '../mock_data/diff_file';

describe('ParallelDiffTableRow', () => {
  describe('when one side is empty', () => {
    let wrapper;
    let vm;
    const thisLine = diffFileMockData.parallel_diff_lines[0];
    const rightLine = diffFileMockData.parallel_diff_lines[0].right;

    beforeEach(() => {
      wrapper = shallowMount(ParallelDiffTableRow, {
        store: createStore(),
        propsData: {
          line: thisLine,
          fileHash: diffFileMockData.file_hash,
          filePath: diffFileMockData.file_path,
          contextLinesPath: 'contextLinesPath',
          isHighlighted: false,
        },
      });

      vm = wrapper.vm;
    });

    it('does not highlight non empty line content when line does not match highlighted row', done => {
      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).not.toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    it('highlights nonempty line content when line is the highlighted row', done => {
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
        line: thisLine,
        fileHash: diffFileMockData.file_hash,
        filePath: diffFileMockData.file_path,
        contextLinesPath: 'contextLinesPath',
        isHighlighted: false,
      }).$mount();
    });

    it('does not highlight  either line when line does not match highlighted row', done => {
      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.line_content.right-side').classList).not.toContain('hll');
          expect(vm.$el.querySelector('.line_content.left-side').classList).not.toContain('hll');
        })
        .then(done)
        .catch(done.fail);
    });

    it('adds hll class to lineContent when line is the highlighted row', done => {
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
      it('for lines with coverage', done => {
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

      it('for lines without coverage', done => {
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

      it('for unknown lines', done => {
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
});
