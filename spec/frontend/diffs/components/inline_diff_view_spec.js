import '~/behaviors/markdown/render_gfm';
import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import { createStore } from '~/mr_notes/stores';
import InlineDiffView from '~/diffs/components/inline_diff_view.vue';
import { mapInline } from '~/diffs/components/diff_row_utils';
import diffFileMockData from '../mock_data/diff_file';
import discussionsMockData from '../mock_data/diff_discussions';

describe('InlineDiffView', () => {
  let wrapper;
  const getDiffFileMock = () => ({ ...diffFileMockData });
  const getDiscussionsMockData = () => [{ ...discussionsMockData }];
  const notesLength = getDiscussionsMockData()[0].notes.length;

  const setup = (diffFile, diffLines) => {
    const mockDiffContent = {
      diffFile,
      shouldRenderDraftRow: jest.fn(),
    };

    const store = createStore();

    store.dispatch('diffs/setInlineDiffViewType');
    wrapper = mount(InlineDiffView, {
      store,
      propsData: {
        diffFile,
        diffLines: diffLines.map(mapInline(mockDiffContent)),
      },
    });
  };

  describe('template', () => {
    it('should have rendered diff lines', () => {
      const diffFile = getDiffFileMock();
      setup(diffFile, diffFile.highlighted_diff_lines);

      expect(wrapper.findAll('tr.line_holder').length).toEqual(8);
      expect(wrapper.findAll('tr.line_holder.new').length).toEqual(4);
      expect(wrapper.findAll('tr.line_expansion.match').length).toEqual(1);
      getByText(wrapper.element, /Bad dates/i);
    });

    it('should render discussions', () => {
      const diffFile = getDiffFileMock();
      diffFile.highlighted_diff_lines[1].discussions = getDiscussionsMockData();
      diffFile.highlighted_diff_lines[1].discussionsExpanded = true;
      setup(diffFile, diffFile.highlighted_diff_lines);

      expect(wrapper.findAll('.notes_holder').length).toEqual(1);
      expect(wrapper.findAll('.notes_holder .note').length).toEqual(notesLength + 1);
      getByText(wrapper.element, 'comment 5');
      wrapper.vm.$store.dispatch('setInitialNotes', []);
    });
  });
});
