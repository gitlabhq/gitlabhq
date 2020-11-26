import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import diffsModule from '~/diffs/store/modules';
import DiffRow from '~/diffs/components/diff_row.vue';

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

  const createWrapper = ({ props, state, isLoggedIn = true }) => {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const diffs = diffsModule();
    diffs.state = { ...diffs.state, ...state };

    const getters = { isLoggedIn: () => isLoggedIn };

    const store = new Vuex.Store({
      modules: { diffs },
      getters,
    });

    const propsData = {
      fileHash: 'abc',
      filePath: 'abc',
      line: {},
      ...props,
    };
    return shallowMount(DiffRow, { propsData, localVue, store });
  };

  it('isHighlighted returns true if isCommented is true', () => {
    const props = { isCommented: true };
    const wrapper = createWrapper({ props });
    expect(wrapper.vm.isHighlighted).toBe(true);
  });

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

  describe.each`
    side
    ${'left'}
    ${'right'}
  `('$side side', ({ side }) => {
    it(`renders empty cells if ${side} is unavailable`, () => {
      const wrapper = createWrapper({ props: { line: testLines[2], inline: false } });
      expect(wrapper.find(`[data-testid="${side}LineNumber"]`).exists()).toBe(false);
      expect(wrapper.find(`[data-testid="${side}EmptyCell"]`).exists()).toBe(true);
    });

    it('renders comment button', () => {
      const wrapper = createWrapper({ props: { line: testLines[3], inline: false } });
      expect(wrapper.find(`[data-testid="${side}CommentButton"]`).exists()).toBe(true);
    });

    it('renders avatars', () => {
      const wrapper = createWrapper({ props: { line: testLines[0], inline: false } });
      expect(wrapper.find(`[data-testid="${side}Discussions"]`).exists()).toBe(true);
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
});
