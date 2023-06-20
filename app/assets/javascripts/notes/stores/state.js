import { ASC, MR_FILTER_OPTIONS } from '../constants';

const createState = () => ({
  discussions: [],
  discussionSortOrder: ASC,
  persistSortOrder: true,
  convertedDisscussionIds: [],
  targetNoteHash: null,
  lastFetchedAt: null,
  currentDiscussionId: null,
  batchSuggestionsInfo: [],
  currentlyFetchingDiscussions: false,
  doneFetchingBatchDiscussions: false,
  /**
   * selectedCommentPosition & selectedCommentPositionHover structures are the same as `position.line_range`:
   * {
   *  start: { line_code: string, new_line: number, old_line:number, type: string },
   *  end: { line_code: string, new_line: number, old_line:number, type: string },
   * }
   */
  selectedCommentPosition: null,
  selectedCommentPositionHover: null,

  // View layer
  isToggleStateButtonLoading: false,
  isNotesFetched: false,
  isLoading: true,
  isLoadingDescriptionVersion: false,
  isPromoteCommentToTimelineEventInProgress: false,

  // holds endpoints and permissions provided through haml
  notesData: {
    markdownDocsPath: '',
  },
  userData: {},
  noteableData: {
    discussion_locked: false,
    confidential: false, // TODO: Move data like this to Issue Store, should not be apart of notes.
    current_user: {},
    preview_note_path: 'path/to/preview',
  },
  isResolvingDiscussion: false,
  commentsDisabled: false,
  resolvableDiscussionsCount: 0,
  unresolvedDiscussionsCount: 0,
  descriptionVersions: {},
  isTimelineEnabled: false,
  isFetching: false,
  isPollingInitialized: false,
  mergeRequestFilters: MR_FILTER_OPTIONS.map((f) => f.value),
});

export default createState;
