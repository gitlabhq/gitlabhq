import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/mr_notes/stores';
import InlineDiffTableRow from '~/diffs/components/inline_diff_table_row.vue';
import diffFileMockData from '../mock_data/diff_file';

describe('InlineDiffTableRow', () => {
  let wrapper;
  let vm;
  const thisLine = diffFileMockData.highlighted_diff_lines[0];

  beforeEach(() => {
    wrapper = shallowMount(InlineDiffTableRow, {
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

  it('does not add hll class to line content when line does not match highlighted row', done => {
    vm.$nextTick()
      .then(() => {
        expect(wrapper.find('.line_content').classes('hll')).toBe(false);
      })
      .then(done)
      .catch(done.fail);
  });

  it('adds hll class to lineContent when line is the highlighted row', done => {
    vm.$nextTick()
      .then(() => {
        vm.$store.state.diffs.highlightedRow = thisLine.line_code;

        return vm.$nextTick();
      })
      .then(() => {
        expect(wrapper.find('.line_content').classes('hll')).toBe(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('adds hll class to lineContent when line is part of a multiline comment', () => {
    wrapper.setProps({ isCommented: true });
    return vm.$nextTick().then(() => {
      expect(wrapper.find('.line_content').classes('hll')).toBe(true);
    });
  });

  describe('sets coverage title and class', () => {
    it('for lines with coverage', done => {
      vm.$nextTick()
        .then(() => {
          const name = diffFileMockData.file_path;
          const line = thisLine.new_line;

          vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 5 } } };

          return vm.$nextTick();
        })
        .then(() => {
          const coverage = wrapper.find('.line-coverage');

          expect(coverage.attributes('title')).toContain('Test coverage: 5 hits');
          expect(coverage.classes('coverage')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('for lines without coverage', done => {
      vm.$nextTick()
        .then(() => {
          const name = diffFileMockData.file_path;
          const line = thisLine.new_line;

          vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 0 } } };

          return vm.$nextTick();
        })
        .then(() => {
          const coverage = wrapper.find('.line-coverage');

          expect(coverage.attributes('title')).toContain('No test coverage');
          expect(coverage.classes('no-coverage')).toBe(true);
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
          const coverage = wrapper.find('.line-coverage');

          expect(coverage.attributes('title')).toBeUndefined();
          expect(coverage.classes('coverage')).toBe(false);
          expect(coverage.classes('no-coverage')).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
