import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffTableCell from '~/diffs/components/diff_table_cell.vue';
import DiffGutterAvatars from '~/diffs/components/diff_gutter_avatars.vue';
import { LINE_POSITION_RIGHT } from '~/diffs/constants';
import { createStore } from '~/mr_notes/stores';
import { TEST_HOST } from 'helpers/test_constants';
import discussionsMockData from '../mock_data/diff_discussions';
import diffFileMockData from '../mock_data/diff_file';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_USER_ID = 'abc123';
const TEST_USER = { id: TEST_USER_ID };
const TEST_LINE_NUMBER = 1;
const TEST_LINE_CODE = 'LC_42';
const TEST_FILE_HASH = diffFileMockData.file_hash;

describe('DiffTableCell', () => {
  let wrapper;
  let line;
  let store;

  beforeEach(() => {
    store = createStore();
    store.state.notes.userData = TEST_USER;

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

  afterEach(() => {
    wrapper.destroy();
  });

  const setWindowLocation = value => {
    Object.defineProperty(window, 'location', {
      writable: true,
      value,
    });
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffTableCell, {
      localVue,
      store,
      propsData: {
        line,
        fileHash: TEST_FILE_HASH,
        contextLinesPath: '/context/lines/path',
        isHighlighted: false,
        ...props,
      },
    });
  };

  const findTd = () => wrapper.find({ ref: 'td' });
  const findNoteButton = () => wrapper.find({ ref: 'addDiffNoteButton' });
  const findLineNumber = () => wrapper.find({ ref: 'lineNumberRef' });
  const findAvatars = () => wrapper.find(DiffGutterAvatars);

  describe('td', () => {
    it('highlights when isHighlighted true', () => {
      createComponent({ isHighlighted: true });

      expect(findTd().classes()).toContain('hll');
    });

    it('does not highlight when isHighlighted false', () => {
      createComponent({ isHighlighted: false });

      expect(findTd().classes()).not.toContain('hll');
    });
  });

  describe('comment button', () => {
    it.each`
      showCommentButton | userData     | query                | mergeRefHeadComments | expectation
      ${true}           | ${TEST_USER} | ${'diff_head=false'} | ${false}             | ${true}
      ${true}           | ${TEST_USER} | ${'diff_head=true'}  | ${true}              | ${true}
      ${true}           | ${TEST_USER} | ${'diff_head=true'}  | ${false}             | ${false}
      ${false}          | ${TEST_USER} | ${'diff_head=true'}  | ${true}              | ${false}
      ${false}          | ${TEST_USER} | ${'bogus'}           | ${true}              | ${false}
      ${true}           | ${null}      | ${''}                | ${true}              | ${false}
    `(
      'exists is $expectation - with showCommentButton ($showCommentButton) userData ($userData) query ($query)',
      ({ showCommentButton, userData, query, mergeRefHeadComments, expectation }) => {
        store.state.notes.userData = userData;
        gon.features = { mergeRefHeadComments };
        setWindowLocation({ href: `${TEST_HOST}?${query}` });
        createComponent({ showCommentButton });

        expect(findNoteButton().exists()).toBe(expectation);
      },
    );

    it.each`
      isHover  | otherProps                                      | discussions | expectation
      ${true}  | ${{}}                                           | ${[]}       | ${true}
      ${false} | ${{}}                                           | ${[]}       | ${false}
      ${true}  | ${{ line: { ...line, type: 'match' } }}         | ${[]}       | ${false}
      ${true}  | ${{ line: { ...line, type: 'context' } }}       | ${[]}       | ${false}
      ${true}  | ${{ line: { ...line, type: 'old-nonewline' } }} | ${[]}       | ${false}
      ${true}  | ${{}}                                           | ${[{}]}     | ${false}
    `(
      'visible is $expectation - with isHover ($isHover), discussions ($discussions), otherProps ($otherProps)',
      ({ isHover, otherProps, discussions, expectation }) => {
        line.discussions = discussions;
        createComponent({
          showCommentButton: true,
          isHover,
          ...otherProps,
        });

        expect(findNoteButton().isVisible()).toBe(expectation);
      },
    );
  });

  describe('line number', () => {
    describe('without lineNumber prop', () => {
      it('does not render', () => {
        createComponent({ lineType: 'old' });

        expect(findLineNumber().exists()).toBe(false);
      });
    });

    describe('with lineNumber prop', () => {
      describe.each`
        lineProps                                                         | expectedHref            | expectedClickArg
        ${{ line_code: TEST_LINE_CODE }}                                  | ${`#${TEST_LINE_CODE}`} | ${TEST_LINE_CODE}
        ${{ line_code: undefined }}                                       | ${'#'}                  | ${undefined}
        ${{ line_code: undefined, left: { line_code: TEST_LINE_CODE } }}  | ${'#'}                  | ${TEST_LINE_CODE}
        ${{ line_code: undefined, right: { line_code: TEST_LINE_CODE } }} | ${'#'}                  | ${TEST_LINE_CODE}
      `('with line ($lineProps)', ({ lineProps, expectedHref, expectedClickArg }) => {
        beforeEach(() => {
          jest.spyOn(store, 'dispatch').mockImplementation();
          Object.assign(line, lineProps);
          createComponent({ lineNumber: TEST_LINE_NUMBER });
        });

        it('renders', () => {
          expect(findLineNumber().exists()).toBe(true);
          expect(findLineNumber().attributes()).toEqual({
            href: expectedHref,
            'data-linenumber': TEST_LINE_NUMBER.toString(),
          });
        });

        it('on click, dispatches setHighlightedRow', () => {
          expect(store.dispatch).not.toHaveBeenCalled();

          findLineNumber().trigger('click');

          expect(store.dispatch).toHaveBeenCalledWith('diffs/setHighlightedRow', expectedClickArg);
        });
      });
    });
  });

  describe('diff-gutter-avatars', () => {
    describe('with showCommentButton', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockImplementation();

        createComponent({ showCommentButton: true });
      });

      it('renders', () => {
        expect(findAvatars().props()).toEqual({
          discussions: line.discussions,
          discussionsExpanded: line.discussionsExpanded,
        });
      });

      it('toggles line discussion', () => {
        expect(store.dispatch).not.toHaveBeenCalled();

        findAvatars().vm.$emit('toggleLineDiscussions');

        expect(store.dispatch).toHaveBeenCalledWith('diffs/toggleLineDiscussions', {
          lineCode: TEST_LINE_CODE,
          fileHash: TEST_FILE_HASH,
          expanded: !line.discussionsExpanded,
        });
      });
    });

    it.each`
      props                                                             | lineProps              | expectation
      ${{ showCommentButton: true }}                                    | ${{}}                  | ${true}
      ${{ showCommentButton: false }}                                   | ${{}}                  | ${false}
      ${{ showCommentButton: true, linePosition: LINE_POSITION_RIGHT }} | ${{ type: null }}      | ${false}
      ${{ showCommentButton: true }}                                    | ${{ discussions: [] }} | ${false}
    `(
      'exists is $expectation - with props ($props), line ($lineProps)',
      ({ props, lineProps, expectation }) => {
        Object.assign(line, lineProps);
        createComponent(props);

        expect(findAvatars().exists()).toBe(expectation);
      },
    );
  });
});
