import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportNoteBody from '~/admin/abuse_report/components/notes/abuse_report_note_body.vue';
import { mockDiscussionWithNoReplies } from '../../mock_data';

describe('Abuse Report Note Body', () => {
  let wrapper;
  const mockNote = mockDiscussionWithNoReplies[0];

  const findNoteBody = () => wrapper.findByTestId('abuse-report-note-body');

  const createComponent = ({ note = mockNote } = {}) => {
    wrapper = shallowMountExtended(AbuseReportNoteBody, {
      propsData: {
        note,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should show the note body', () => {
    expect(findNoteBody().exists()).toBe(true);
    expect(findNoteBody().html()).toMatchSnapshot();
  });
});
