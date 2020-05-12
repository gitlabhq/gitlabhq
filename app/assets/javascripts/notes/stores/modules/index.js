import * as actions from '../actions';
import * as getters from '../getters';
import mutations from '../mutations';
import { ASC } from '../../constants';

export default () => ({
  state: {
    discussions: [],
    discussionSortOrder: ASC,
    convertedDisscussionIds: [],
    targetNoteHash: null,
    lastFetchedAt: null,
    currentDiscussionId: null,

    // View layer
    isToggleStateButtonLoading: false,
    isToggleBlockedIssueWarning: false,
    isNotesFetched: false,
    isLoading: true,
    isLoadingDescriptionVersion: false,

    // holds endpoints and permissions provided through haml
    notesData: {
      markdownDocsPath: '',
    },
    userData: {},
    noteableData: {
      confidential: false, // TODO: Move data like this to Issue Store, should not be apart of notes.
      current_user: {},
      preview_note_path: 'path/to/preview',
    },
    commentsDisabled: false,
    resolvableDiscussionsCount: 0,
    unresolvedDiscussionsCount: 0,
    descriptionVersions: {},
  },
  actions,
  getters,
  mutations,
});
