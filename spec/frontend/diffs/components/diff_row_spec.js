import { getByTestId, fireEvent } from '@testing-library/dom';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import DiffRow from '~/diffs/components/diff_row.vue';
import { mapParallel } from '~/diffs/components/diff_row_utils';
import diffsModule from '~/diffs/store/modules';
import { findInteropAttributes } from '../find_interop_attributes';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffRow', () => {
  const testLines = [
    {
      left: { old_line: 1, discussions: [] },
      right: { new_line: 1, discussions: [] },
      hasDiscussionsLeft: true,
      hasDiscussionsRight: true,
    },
    {
      left: {},
      right: {},
      isMatchLineLeft: true,
      isMatchLineRight: true,
    },
    {},
    {
      left: { old_line: 1, discussions: [] },
      right: { new_line: 1, discussions: [] },
    },
  ];

  const createWrapper = ({ props, state, actions, isLoggedIn = true }) => {
    Vue.use(Vuex);

    const diffs = diffsModule();
    diffs.state = { ...diffs.state, ...state };
    diffs.actions = { ...diffs.actions, ...actions };

    const getters = { isLoggedIn: () => isLoggedIn };

    const store = new Vuex.Store({
      modules: { diffs },
      getters,
    });

    const propsData = {
      fileHash: 'abc',
      filePath: 'abc',
      line: {},
      index: 0,
      ...props,
    };

    const provide = {
      glFeatures: { dragCommentSelection: true },
    };

    return shallowMount(DiffRow, { propsData, store, provide });
  };

  it('isHighlighted returns true given line.left', () => {
    const props = {
      line: {
        left: {
          line_code: 'abc',
        },
      },
    };
    const state = { highlightedRow: 'abc' };
    const wrapper = createWrapper({ props, state });
    expect(wrapper.vm.isHighlighted).toBe(true);
  });

  it('isHighlighted returns true given line.right', () => {
    const props = {
      line: {
        right: {
          line_code: 'abc',
        },
      },
    };
    const state = { highlightedRow: 'abc' };
    const wrapper = createWrapper({ props, state });
    expect(wrapper.vm.isHighlighted).toBe(true);
  });

  it('isHighlighted returns false given line.left', () => {
    const props = {
      line: {
        left: {
          line_code: 'abc',
        },
      },
    };
    const wrapper = createWrapper({ props });
    expect(wrapper.vm.isHighlighted).toBe(false);
  });

  const getCommentButton = (wrapper, side) =>
    wrapper.find(`[data-testid="${side}-comment-button"]`);

  describe.each`
    side
    ${'left'}
    ${'right'}
  `('$side side', ({ side }) => {
    it(`renders empty cells if ${side} is unavailable`, () => {
      const wrapper = createWrapper({ props: { line: testLines[2], inline: false } });
      expect(wrapper.find(`[data-testid="${side}-line-number"]`).exists()).toBe(false);
      expect(wrapper.find(`[data-testid="${side}-empty-cell"]`).exists()).toBe(true);
    });

    describe('comment button', () => {
      const showCommentForm = jest.fn();
      let line;

      beforeEach(() => {
        showCommentForm.mockReset();
        // https://eslint.org/docs/rules/prefer-destructuring#when-not-to-use-it
        // eslint-disable-next-line prefer-destructuring
        line = testLines[3];
      });

      it('renders', () => {
        const wrapper = createWrapper({ props: { line, inline: false } });
        expect(getCommentButton(wrapper, side).exists()).toBe(true);
      });

      it('responds to click and keyboard events', async () => {
        const wrapper = createWrapper({
          props: { line, inline: false },
          actions: { showCommentForm },
        });
        const commentButton = getCommentButton(wrapper, side);

        await commentButton.trigger('click');
        await commentButton.trigger('keydown.enter');
        await commentButton.trigger('keydown.space');

        expect(showCommentForm).toHaveBeenCalledTimes(3);
      });

      it('ignores click and keyboard events when comments are disabled', async () => {
        line[side].commentsDisabled = true;
        const wrapper = createWrapper({
          props: { line, inline: false },
          actions: { showCommentForm },
        });
        const commentButton = getCommentButton(wrapper, side);

        await commentButton.trigger('click');
        await commentButton.trigger('keydown.enter');
        await commentButton.trigger('keydown.space');

        expect(showCommentForm).not.toHaveBeenCalled();
      });
    });

    it('renders avatars', () => {
      const wrapper = createWrapper({ props: { line: testLines[0], inline: false } });
      expect(wrapper.find(`[data-testid="${side}-discussions"]`).exists()).toBe(true);
    });
  });

  it('renders left line numbers', () => {
    const wrapper = createWrapper({ props: { line: testLines[0] } });
    const lineNumber = testLines[0].left.old_line;
    expect(wrapper.find(`[data-linenumber="${lineNumber}"]`).exists()).toBe(true);
  });

  it('renders right line numbers', () => {
    const wrapper = createWrapper({ props: { line: testLines[0] } });
    const lineNumber = testLines[0].right.new_line;
    expect(wrapper.find(`[data-linenumber="${lineNumber}"]`).exists()).toBe(true);
  });

  describe('drag operations', () => {
    let line;

    beforeEach(() => {
      line = { ...testLines[0] };
    });

    it.each`
      side
      ${'left'}
      ${'right'}
    `('emits `enterdragging` onDragEnter $side side', ({ side }) => {
      const expectation = { ...line[side], index: 0 };
      const wrapper = createWrapper({ props: { line } });
      fireEvent.dragEnter(getByTestId(wrapper.element, `${side}-side`));

      expect(wrapper.emitted().enterdragging).toBeTruthy();
      expect(wrapper.emitted().enterdragging[0]).toEqual([expectation]);
    });

    it.each`
      side
      ${'left'}
      ${'right'}
    `('emits `stopdragging` onDrop $side side', ({ side }) => {
      const wrapper = createWrapper({ props: { line } });
      fireEvent.dragEnd(getByTestId(wrapper.element, `${side}-side`));

      expect(wrapper.emitted().stopdragging).toBeTruthy();
    });
  });

  describe('sets coverage title and class', () => {
    const thisLine = diffFileMockData.parallel_diff_lines[2];
    const rightLine = diffFileMockData.parallel_diff_lines[2].right;

    const mockDiffContent = {
      diffFile: diffFileMockData,
      shouldRenderDraftRow: jest.fn(),
      hasParallelDraftLeft: jest.fn(),
      hasParallelDraftRight: jest.fn(),
      draftForLine: jest.fn(),
    };

    const applyMap = mapParallel(mockDiffContent);
    const props = {
      line: applyMap(thisLine),
      fileHash: diffFileMockData.file_hash,
      filePath: diffFileMockData.file_path,
      contextLinesPath: 'contextLinesPath',
      isHighlighted: false,
    };
    const name = diffFileMockData.file_path;
    const line = rightLine.new_line;

    it('for lines with coverage', () => {
      const coverageFiles = { files: { [name]: { [line]: 5 } } };
      const wrapper = createWrapper({ props, state: { coverageFiles } });
      const coverage = wrapper.find('.line-coverage.right-side');

      expect(coverage.attributes('title')).toContain('Test coverage: 5 hits');
      expect(coverage.classes('coverage')).toBeTruthy();
    });

    it('for lines without coverage', () => {
      const coverageFiles = { files: { [name]: { [line]: 0 } } };
      const wrapper = createWrapper({ props, state: { coverageFiles } });
      const coverage = wrapper.find('.line-coverage.right-side');

      expect(coverage.attributes('title')).toContain('No test coverage');
      expect(coverage.classes('no-coverage')).toBeTruthy();
    });

    it('for unknown lines', () => {
      const coverageFiles = {};
      const wrapper = createWrapper({ props, state: { coverageFiles } });
      const coverage = wrapper.find('.line-coverage.right-side');

      expect(coverage.attributes('title')).toBeFalsy();
      expect(coverage.classes('coverage')).toBeFalsy();
      expect(coverage.classes('no-coverage')).toBeFalsy();
    });
  });

  describe('interoperability', () => {
    it.each`
      desc                                 | line                                                   | inline   | leftSide                                                  | rightSide
      ${'with inline and new_line'}        | ${{ left: { old_line: 3, new_line: 5, type: 'new' } }} | ${true}  | ${{ type: 'new', line: '5', oldLine: '3', newLine: '5' }} | ${null}
      ${'with inline and no new_line'}     | ${{ left: { old_line: 3, type: 'old' } }}              | ${true}  | ${{ type: 'old', line: '3', oldLine: '3' }}               | ${null}
      ${'with parallel and no right side'} | ${{ left: { old_line: 3, new_line: 5 } }}              | ${false} | ${{ type: 'old', line: '3', oldLine: '3' }}               | ${null}
      ${'with parallel and no left side'}  | ${{ right: { old_line: 3, new_line: 5 } }}             | ${false} | ${null}                                                   | ${{ type: 'new', line: '5', newLine: '5' }}
      ${'with parallel and right side'}    | ${{ left: { old_line: 3 }, right: { new_line: 5 } }}   | ${false} | ${{ type: 'old', line: '3', oldLine: '3' }}               | ${{ type: 'new', line: '5', newLine: '5' }}
    `('$desc, sets interop data attributes', ({ line, inline, leftSide, rightSide }) => {
      const wrapper = createWrapper({ props: { line, inline } });

      expect(findInteropAttributes(wrapper, '[data-testid="left-side"]')).toEqual(leftSide);
      expect(findInteropAttributes(wrapper, '[data-testid="right-side"]')).toEqual(rightSide);
    });
  });
});
