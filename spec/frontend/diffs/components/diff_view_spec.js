import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { throttle } from 'lodash';
import { PiniaVuePlugin } from 'pinia';
import DiffView from '~/diffs/components/diff_view.vue';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { createCustomGetters } from 'helpers/pinia_helpers';

Vue.use(Vuex);
Vue.use(PiniaVuePlugin);

jest.mock('lodash/throttle', () => jest.fn((fn) => fn));
const lodash = jest.requireActual('lodash');

describe('DiffView', () => {
  let pinia;

  const DiffExpansionCell = { template: `<div/>` };
  const DiffRow = { template: `<div/>` };
  const DiffCommentCell = { template: `<div/>` };
  const showCommentForm = jest.fn();
  const setSelectedCommentPosition = jest.fn();
  const getDiffRow = (wrapper) => wrapper.findComponent(DiffRow).vm;

  const createWrapper = ({ props } = {}) => {
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
      modules: { diffs, notes },
    });

    const propsData = {
      diffFile: { file_hash: '123' },
      diffLines: [],
      autosaveKey: 'autosave',
      ...props,
    };

    const stubs = { DiffExpansionCell, DiffRow, DiffCommentCell };
    return shallowMount(DiffView, { propsData, pinia, store, stubs });
  };

  beforeEach(() => {
    throttle.mockImplementation(lodash.throttle);
    pinia = createTestingPinia({
      plugins: [
        globalAccessorPlugin,
        createCustomGetters(() => ({
          legacyNotes: {},
          legacyDiffs: {},
          batchComments: {
            shouldRenderDraftRow: () => false,
            shouldRenderParallelDraftRow: () => () => true,
            draftsForLine: () => false,
            draftsForFile: () => false,
            hasParallelDraftLeft: () => false,
            hasParallelDraftRight: () => false,
          },
        })),
      ],
    });
    useLegacyDiffs();
    useNotes();
  });

  afterEach(() => {
    throttle.mockReset();
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
        props: {
          diffLines: [{ renderCommentRow: true, ...sides }],
          inline: type === 'inline',
        },
      });
      expect(wrapper.findAllComponents(DiffCommentCell).length).toBe(total);
      expect(wrapper.find(container).findComponent(DiffCommentCell).exists()).toBe(true);
    },
  );

  it('renders a draft row', () => {
    const wrapper = createWrapper({
      props: { diffLines: [{ renderCommentRow: true, left: { lineDrafts: [{ isDraft: true }] } }] },
    });
    expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
    expect(wrapper.findComponent(DraftNote).props('autosaveKey')).toBe('autosave');
  });

  describe('drag operations', () => {
    it('sets `dragStart` onStartDragging', () => {
      const wrapper = createWrapper({ props: { diffLines: [{}] } });
      wrapper.findComponent(DiffRow).vm.$emit('startdragging', { line: { test: true } });
      expect(wrapper.vm.idState.dragStart).toEqual({ test: true });
    });

    it('does not call `setSelectedCommentPosition` on different chunks onDragOver', () => {
      const wrapper = createWrapper({ props: { diffLines: [{}] } });
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
        const wrapper = createWrapper({ props: { diffLines: [{}] } });
        const diffRow = getDiffRow(wrapper);

        diffRow.$emit('startdragging', { line: { chunk: 1, index: start } });
        diffRow.$emit('enterdragging', { chunk: 1, index: end });

        const arg = setSelectedCommentPosition.mock.calls[0][1];

        expect(arg).toMatchObject(expectation);
      },
    );

    it('sets `dragStart` to null onStopDragging', () => {
      const wrapper = createWrapper({ props: { diffLines: [{}] } });
      const diffRow = getDiffRow(wrapper);

      diffRow.$emit('startdragging', { line: { test: true } });
      expect(wrapper.vm.idState.dragStart).toEqual({ test: true });

      diffRow.$emit('stopdragging');
      expect(wrapper.vm.idState.dragStart).toBeNull();
      expect(showCommentForm).toHaveBeenCalled();
    });

    it('throttles multiple calls to enterdragging', () => {
      const wrapper = createWrapper({ props: { diffLines: [{}] } });

      const diffRow = getDiffRow(wrapper);

      diffRow.$emit('startdragging', { line: { chunk: 1, index: 1 } });
      diffRow.$emit('enterdragging', { chunk: 1, index: 2 });
      diffRow.$emit('enterdragging', { chunk: 1, index: 2 });

      jest.runOnlyPendingTimers();

      expect(setSelectedCommentPosition).toHaveBeenCalledTimes(1);
    });
  });
});
