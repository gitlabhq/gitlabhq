import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffView from '~/diffs/components/diff_view.vue';
// import DraftNote from '~/batch_comments/components/draft_note.vue';
// import DiffRow from '~/diffs/components/diff_row.vue';
// import DiffCommentCell from '~/diffs/components/diff_comment_cell.vue';
// import DiffExpansionCell from '~/diffs/components/diff_expansion_cell.vue';

describe('DiffView', () => {
  const DiffExpansionCell = { template: `<div/>` };
  const DiffRow = { template: `<div/>` };
  const DiffCommentCell = { template: `<div/>` };
  const DraftNote = { template: `<div/>` };
  const createWrapper = props => {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const batchComments = {
      getters: {
        shouldRenderDraftRow: () => false,
        shouldRenderParallelDraftRow: () => () => true,
        draftForLine: () => false,
        draftsForFile: () => false,
        hasParallelDraftLeft: () => false,
        hasParallelDraftRight: () => false,
      },
      namespaced: true,
    };
    const diffs = { getters: { commitId: () => 'abc123' }, namespaced: true };
    const notes = {
      state: { selectedCommentPosition: null, selectedCommentPositionHover: null },
    };

    const store = new Vuex.Store({
      modules: { diffs, notes, batchComments },
    });

    const propsData = {
      diffFile: {},
      diffLines: [],
      ...props,
    };
    const stubs = { DiffExpansionCell, DiffRow, DiffCommentCell, DraftNote };
    return shallowMount(DiffView, { propsData, store, localVue, stubs });
  };

  it('renders a match line', () => {
    const wrapper = createWrapper({ diffLines: [{ isMatchLineLeft: true }] });
    expect(wrapper.find(DiffExpansionCell).exists()).toBe(true);
  });

  it('renders a comment row', () => {
    const wrapper = createWrapper({
      diffLines: [{ renderCommentRow: true, left: { lineDraft: {} } }],
    });
    expect(wrapper.find(DiffCommentCell).exists()).toBe(true);
  });

  it('renders a draft row', () => {
    const wrapper = createWrapper({
      diffLines: [{ renderCommentRow: true, left: { lineDraft: { isDraft: true } } }],
    });
    expect(wrapper.find(DraftNote).exists()).toBe(true);
  });
});
