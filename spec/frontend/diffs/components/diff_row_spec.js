import { getByTestId, fireEvent } from '@testing-library/dom';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import DiffRow from '~/diffs/components/diff_row.vue';
import { mapParallel } from '~/diffs/components/diff_row_utils';
import diffsModule from '~/diffs/store/modules';
import { findInteropAttributes } from '../find_interop_attributes';
import diffFileMockData from '../mock_data/diff_file';

const showCommentForm = jest.fn();
const enterdragging = jest.fn();
const stopdragging = jest.fn();
const setHighlightedRow = jest.fn();
let wrapper;

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

  const createWrapper = ({ props, state = {}, actions, isLoggedIn = true }) => {
    Vue.use(Vuex);

    const diffs = diffsModule();
    diffs.state = { ...diffs.state, ...state };
    diffs.actions = { ...diffs.actions, ...actions };

    const getters = { isLoggedIn: () => isLoggedIn };

    const store = new Vuex.Store({
      modules: { diffs },
      getters,
    });

    window.gon = { current_user_id: isLoggedIn ? 1 : 0 };
    const coverageFileData = state.coverageFiles?.files ? state.coverageFiles.files : {};

    const propsData = {
      fileHash: 'abc',
      filePath: 'abc',
      line: {},
      index: 0,
      isHighlighted: false,
      fileLineCoverage: (file, line) => {
        const hits = coverageFileData[file]?.[line];
        if (hits) {
          return { text: `Test coverage: ${hits} hits`, class: 'coverage' };
        } else if (hits === 0) {
          return { text: 'No test coverage', class: 'no-coverage' };
        }

        return {};
      },
      ...props,
    };

    const provide = {
      glFeatures: { dragCommentSelection: true },
    };

    return shallowMount(DiffRow, {
      propsData,
      store,
      provide,
      listeners: {
        enterdragging,
        stopdragging,
        setHighlightedRow,
        showCommentForm,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    window.gon = {};
    showCommentForm.mockReset();
    enterdragging.mockReset();
    stopdragging.mockReset();
    setHighlightedRow.mockReset();

    Object.values(DiffRow).forEach(({ cache }) => {
      if (cache) {
        cache.clear();
      }
    });
  });

  const getCommentButton = (side) => wrapper.find(`[data-testid="${side}-comment-button"]`);

  describe.each`
    side
    ${'left'}
    ${'right'}
  `('$side side', ({ side }) => {
    it(`renders empty cells if ${side} is unavailable`, () => {
      wrapper = createWrapper({ props: { line: testLines[2], inline: false } });
      expect(wrapper.find(`[data-testid="${side}-line-number"]`).exists()).toBe(false);
      expect(wrapper.find(`[data-testid="${side}-empty-cell"]`).exists()).toBe(true);
    });

    describe('comment button', () => {
      let line;

      beforeEach(() => {
        // https://eslint.org/docs/rules/prefer-destructuring#when-not-to-use-it
        // eslint-disable-next-line prefer-destructuring
        line = testLines[3];
      });

      it('renders', () => {
        wrapper = createWrapper({ props: { line, inline: false } });
        expect(getCommentButton(side).exists()).toBe(true);
      });

      it('responds to click and keyboard events', async () => {
        wrapper = createWrapper({
          props: { line, inline: false },
        });
        const commentButton = getCommentButton(side);

        await commentButton.trigger('click');
        await commentButton.trigger('keydown.enter');
        await commentButton.trigger('keydown.space');

        expect(showCommentForm).toHaveBeenCalledTimes(3);
      });

      it('ignores click and keyboard events when comments are disabled', async () => {
        line[side].commentsDisabled = true;
        wrapper = createWrapper({
          props: { line, inline: false },
        });
        const commentButton = getCommentButton(side);

        await commentButton.trigger('click');
        await commentButton.trigger('keydown.enter');
        await commentButton.trigger('keydown.space');

        expect(showCommentForm).not.toHaveBeenCalled();
      });
    });

    it('renders avatars', () => {
      wrapper = createWrapper({ props: { line: testLines[0], inline: false } });

      expect(wrapper.find(`[data-testid="${side}-discussions"]`).exists()).toBe(true);
    });
  });

  it('renders left line numbers', () => {
    wrapper = createWrapper({ props: { line: testLines[0] } });
    const lineNumber = testLines[0].left.old_line;
    expect(wrapper.find(`[data-linenumber="${lineNumber}"]`).exists()).toBe(true);
  });

  it('renders right line numbers', () => {
    wrapper = createWrapper({ props: { line: testLines[0] } });
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
      wrapper = createWrapper({ props: { line } });
      fireEvent.dragEnter(getByTestId(wrapper.element, `${side}-side`));

      expect(enterdragging).toHaveBeenCalledWith({ ...line[side], index: 0 });
    });

    it.each`
      side
      ${'left'}
      ${'right'}
    `('emits `stopdragging` onDrop $side side', ({ side }) => {
      wrapper = createWrapper({ props: { line } });
      fireEvent.dragEnd(getByTestId(wrapper.element, `${side}-side`));

      expect(stopdragging).toHaveBeenCalled();
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
      wrapper = createWrapper({ props, state: { coverageFiles } });
      const coverage = wrapper.find('.line-coverage.right-side');

      expect(coverage.attributes('title')).toContain('Test coverage: 5 hits');
      expect(coverage.classes('coverage')).toBeTruthy();
    });

    it('for lines without coverage', () => {
      const coverageFiles = { files: { [name]: { [line]: 0 } } };
      wrapper = createWrapper({ props, state: { coverageFiles } });
      const coverage = wrapper.find('.line-coverage.right-side');

      expect(coverage.attributes('title')).toContain('No test coverage');
      expect(coverage.classes('no-coverage')).toBeTruthy();
    });

    it('for unknown lines', () => {
      const coverageFiles = {};
      wrapper = createWrapper({ props, state: { coverageFiles } });
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
      wrapper = createWrapper({ props: { line, inline } });

      expect(findInteropAttributes(wrapper, '[data-testid="left-side"]')).toEqual(leftSide);
      expect(findInteropAttributes(wrapper, '[data-testid="right-side"]')).toEqual(rightSide);
    });
  });
});
