import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import DiffView from '~/diffs/components/diff_view.vue';
import DiffLine from '~/diffs/components/diff_line.vue';
import { diffCodeQuality } from '../mock_data/diff_code_quality';

describe('DiffView', () => {
  const DiffExpansionCell = { template: `<div/>` };
  const DiffRow = { template: `<div/>` };
  const DiffCommentCell = { template: `<div/>` };
  const DraftNote = { template: `<div/>` };
  const showCommentForm = jest.fn();
  const setSelectedCommentPosition = jest.fn();
  const getDiffRow = (wrapper) => wrapper.findComponent(DiffRow).vm;

  const createWrapper = (props) => {
    Vue.use(Vuex);

    const batchComments = {
      getters: {
        shouldRenderDraftRow: () => false,
        shouldRenderParallelDraftRow: () => () => true,
        draftsForLine: () => false,
        draftsForFile: () => false,
        hasParallelDraftLeft: () => false,
        hasParallelDraftRight: () => false,
      },
      namespaced: true,
    };
    const diffs = {
      actions: { showCommentForm },
      getters: { commitId: () => 'abc123', fileLineCoverage: () => ({}) },
      namespaced: true,
    };
    const notes = {
      actions: { setSelectedCommentPosition },
      state: { selectedCommentPosition: null, selectedCommentPositionHover: null },
    };

    const store = new Vuex.Store({
      modules: { diffs, notes, batchComments },
    });

    const propsData = {
      diffFile: { file_hash: '123' },
      diffLines: [],
      ...props,
    };
    const stubs = { DiffExpansionCell, DiffRow, DiffCommentCell, DraftNote };
    return shallowMount(DiffView, { propsData, store, stubs });
  };

  it('does not render a diff-line component when there is no finding', () => {
    const wrapper = createWrapper();
    expect(wrapper.findComponent(DiffLine).exists()).toBe(false);
  });

  it('does render a diff-line component with the correct props when there is a finding', async () => {
    const wrapper = createWrapper(diffCodeQuality);
    wrapper.findComponent(DiffRow).vm.$emit('toggleCodeQualityFindings', 2);
    await nextTick();
    expect(wrapper.findComponent(DiffLine).props('line')).toBe(diffCodeQuality.diffLines[2]);
  });

  it.each`
    type          | side       | container | sides                                                                                                      | total
    ${'parallel'} | ${'left'}  | ${'.old'} | ${{ left: { lineDrafts: [], renderDiscussion: true }, right: { lineDrafts: [], renderDiscussion: true } }} | ${2}
    ${'parallel'} | ${'right'} | ${'.new'} | ${{ left: { lineDrafts: [], renderDiscussion: true }, right: { lineDrafts: [], renderDiscussion: true } }} | ${2}
    ${'inline'}   | ${'left'}  | ${'.old'} | ${{ left: { lineDrafts: [], renderDiscussion: true } }}                                                    | ${1}
    ${'inline'}   | ${'left'}  | ${'.old'} | ${{ left: { lineDrafts: [], renderDiscussion: true } }}                                                    | ${1}
    ${'inline'}   | ${'left'}  | ${'.old'} | ${{ left: { lineDrafts: [], renderDiscussion: true } }}                                                    | ${1}
  `(
    'renders a $type comment row with comment cell on $side',
    ({ type, container, sides, total }) => {
      const wrapper = createWrapper({
        diffLines: [{ renderCommentRow: true, ...sides }],
        inline: type === 'inline',
      });
      expect(wrapper.findAllComponents(DiffCommentCell).length).toBe(total);
      expect(wrapper.find(container).findComponent(DiffCommentCell).exists()).toBe(true);
    },
  );

  it('renders a draft row', () => {
    const wrapper = createWrapper({
      diffLines: [{ renderCommentRow: true, left: { lineDrafts: [{ isDraft: true }] } }],
    });
    expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
  });

  describe('drag operations', () => {
    it('sets `dragStart` onStartDragging', () => {
      const wrapper = createWrapper({ diffLines: [{}] });

      wrapper.findComponent(DiffRow).vm.$emit('startdragging', { line: { test: true } });
      expect(wrapper.vm.idState.dragStart).toEqual({ test: true });
    });

    it('does not call `setSelectedCommentPosition` on different chunks onDragOver', () => {
      const wrapper = createWrapper({ diffLines: [{}] });
      const diffRow = getDiffRow(wrapper);

      diffRow.$emit('startdragging', { line: { chunk: 0 } });
      diffRow.$emit('enterdragging', { chunk: 1 });

      expect(setSelectedCommentPosition).not.toHaveBeenCalled();
    });

    it.each`
      start | end  | expectation
      ${1}  | ${2} | ${{ start: { index: 1 }, end: { index: 2 } }}
      ${2}  | ${1} | ${{ start: { index: 1 }, end: { index: 2 } }}
      ${1}  | ${1} | ${{ start: { index: 1 }, end: { index: 1 } }}
    `(
      'calls `setSelectedCommentPosition` with correct `updatedLineRange`',
      ({ start, end, expectation }) => {
        const wrapper = createWrapper({ diffLines: [{}] });
        const diffRow = getDiffRow(wrapper);

        diffRow.$emit('startdragging', { line: { chunk: 1, index: start } });
        diffRow.$emit('enterdragging', { chunk: 1, index: end });

        const arg = setSelectedCommentPosition.mock.calls[0][1];

        expect(arg).toMatchObject(expectation);
      },
    );

    it('sets `dragStart` to null onStopDragging', () => {
      const wrapper = createWrapper({ diffLines: [{}] });
      const diffRow = getDiffRow(wrapper);

      diffRow.$emit('startdragging', { line: { test: true } });
      expect(wrapper.vm.idState.dragStart).toEqual({ test: true });

      diffRow.$emit('stopdragging');
      expect(wrapper.vm.idState.dragStart).toBeNull();
      expect(showCommentForm).toHaveBeenCalled();
    });
  });
});
