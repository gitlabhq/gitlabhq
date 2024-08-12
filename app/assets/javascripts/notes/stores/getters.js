import { flattenDeep, clone } from 'lodash';
import { match } from '~/diffs/utils/diff_file';
import { isInMRPage } from '~/lib/utils/common_utils';
import { doesHashExistInUrl } from '~/lib/utils/url_utility';
import { badgeState } from '~/merge_requests/components/merge_request_header.vue';
import * as constants from '../constants';
import { collapseSystemNotes } from './collapse_utils';

const getDraftComments = (state) => {
  if (!state.batchComments) {
    return [];
  }

  return state.batchComments.drafts
    .filter((draft) => !draft.file_path && !draft.discussion_id)
    .map((x) => ({
      ...x,
      // Treat a top-level draft note as individual_note so it's not included in
      // expand/collapse threads
      individual_note: true,
    }))
    .sort((a, b) => a.id - b.id);
};

const hideActivity = (filters, discussion) => {
  if (filters.length === constants.MR_FILTER_OPTIONS) return false;
  if (filters.length === 0) return true;

  const firstNote = discussion.notes[0];
  const hidingFilters = constants.MR_FILTER_OPTIONS.filter(({ value }) => !filters.includes(value));

  for (let i = 0, len = hidingFilters.length; i < len; i += 1) {
    const filter = hidingFilters[i];

    if (
      // For all of the below firstNote is the first note of a discussion, whether that be
      // the first in a discussion or a single note
      // If the filter option filters based on icon check against the first notes system note icon
      filter.systemNoteIcons?.includes(firstNote.system_note_icon_name) ||
      // If the filter option filters based on note type use the first notes type
      (filter.noteType?.includes(firstNote.type) && !firstNote.author?.bot) ||
      // If the filter option filters based on the note text then check if it is sytem
      // and filter based on the text of the system note
      (firstNote.system && filter.noteText?.some((t) => firstNote.note.includes(t))) ||
      // For individual notes we filter if the discussion is a single note and is not a sytem
      (filter.individualNote === discussion.individual_note &&
        !firstNote.system &&
        !firstNote.author?.bot) ||
      // For bot comments we filter on the authors `bot` boolean attribute
      (filter.bot && firstNote.author?.bot)
    ) {
      return true;
    }
  }

  return false;
};

export const discussions = (state, getters, rootState) => {
  let discussionsInState = clone(state.discussions);
  // NOTE: not testing bc will be removed when backend is finished.

  if (state.noteableData.targetType === 'merge_request') {
    discussionsInState = discussionsInState.reduce((acc, discussion) => {
      if (hideActivity(state.mergeRequestFilters, discussion)) {
        return acc;
      }

      acc.push(discussion);

      return acc;
    }, []);
  }

  if (state.isTimelineEnabled) {
    discussionsInState = discussionsInState
      .reduce((acc, discussion) => {
        const transformedToIndividualNotes = discussion.notes.map((note) => ({
          ...discussion,
          id: note.id,
          created_at: note.created_at,
          individual_note: true,
          notes: [note],
        }));

        return acc.concat(transformedToIndividualNotes);
      }, [])
      .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  }

  discussionsInState = collapseSystemNotes(discussionsInState);

  discussionsInState = discussionsInState.concat(getDraftComments(rootState));

  if (state.discussionSortOrder === constants.DESC) {
    discussionsInState = discussionsInState.reverse();
  }

  return discussionsInState;
};

export const convertedDisscussionIds = (state) => state.convertedDisscussionIds;

export const targetNoteHash = (state) => state.targetNoteHash;

export const getNotesData = (state) => state.notesData;

export const isNotesFetched = (state) => state.isNotesFetched;

/*
 * WARNING: This is an example of an "unnecessary" getter
 * more info found here: https://gitlab.com/groups/gitlab-org/-/epics/2913.
 */

export const sortDirection = (state) => state.discussionSortOrder;

export const persistSortOrder = (state) => state.persistSortOrder;

export const timelineEnabled = (state) => state.isTimelineEnabled;

export const isFetching = (state) => state.isFetching;

export const isLoading = (state) => state.isLoading;

export const getNotesDataByProp = (state) => (prop) => state.notesData[prop];

export const getNoteableData = (state) => state.noteableData;

export const getNoteableDataByProp = (state) => (prop) => state.noteableData[prop];

export const getBlockedByIssues = (state) => state.noteableData.blocked_by_issues;

export const userCanReply = (state) => Boolean(state.noteableData.current_user.can_create_note);

export const openState = (state) => (isInMRPage() ? badgeState.state : state.noteableData.state);

export const getUserData = (state) => state.userData || {};

export const getUserDataByProp = (state) => (prop) => state.userData && state.userData[prop];

export const descriptionVersions = (state) => state.descriptionVersions;

export const canUserAddIncidentTimelineEvents = (state) => {
  return Boolean(
    state.userData?.can_add_timeline_events &&
      state.noteableData.type === constants.NOTEABLE_TYPE_MAPPING.Incident,
  );
};

export const notesById = (state) =>
  state.discussions.reduce((acc, note) => {
    note.notes.every((n) => Object.assign(acc, { [n.id]: n }));
    return acc;
  }, {});

export const noteableType = (state) => {
  const { ISSUE_NOTEABLE_TYPE, MERGE_REQUEST_NOTEABLE_TYPE, EPIC_NOTEABLE_TYPE } = constants;

  if (state.noteableData.noteableType === EPIC_NOTEABLE_TYPE) {
    return EPIC_NOTEABLE_TYPE;
  }

  return state.noteableData.merge_params ? MERGE_REQUEST_NOTEABLE_TYPE : ISSUE_NOTEABLE_TYPE;
};

const reverseNotes = (array) => array.slice(0).reverse();

const isLastNote = (note, state) =>
  !note.system && state.userData && note.author && note.author.id === state.userData.id;

export const getCurrentUserLastNote = (state) =>
  flattenDeep(reverseNotes(state.discussions).map((note) => reverseNotes(note.notes))).find((el) =>
    isLastNote(el, state),
  );

export const getDiscussionLastNote = (state) => (discussion) =>
  reverseNotes(discussion.notes).find((el) => isLastNote(el, state));

export const unresolvedDiscussionsCount = (state) => state.unresolvedDiscussionsCount;
export const resolvableDiscussionsCount = (state) => state.resolvableDiscussionsCount;

export const showJumpToNextDiscussion =
  (state, getters) =>
  (mode = 'discussion') => {
    const orderedDiffs =
      mode !== 'discussion'
        ? getters.unresolvedDiscussionsIdsByDiff
        : getters.unresolvedDiscussionsIdsByDate;

    return orderedDiffs.length > 1;
  };

export const isDiscussionResolved = (state, getters) => (discussionId) =>
  getters.resolvedDiscussionsById[discussionId] !== undefined;

export const allResolvableDiscussions = (state) =>
  state.discussions.filter((d) => !d.individual_note && d.resolvable);

export const resolvedDiscussionsById = (state) => {
  const map = {};

  state.discussions
    .filter((d) => d.resolvable)
    .forEach((n) => {
      if (n.notes) {
        const resolved = n.notes.filter((note) => note.resolvable).every((note) => note.resolved);

        if (resolved) {
          map[n.id] = n;
        }
      }
    });

  return map;
};

// Gets Discussions IDs ordered by the date of their initial note
export const unresolvedDiscussionsIdsByDate = (state, getters) =>
  getters.allResolvableDiscussions
    .filter((d) => !d.resolved)
    .sort((a, b) => {
      const aDate = new Date(a.notes[0].created_at);
      const bDate = new Date(b.notes[0].created_at);

      if (aDate < bDate) {
        return -1;
      }

      return aDate === bDate ? 0 : 1;
    })
    .map((d) => d.id);

// Gets Discussions IDs ordered by their position in the diff
//
// Sorts the array of resolvable yet unresolved discussions by
// comparing file names first. If file names are the same, compares
// line numbers.
export const unresolvedDiscussionsIdsByDiff = (state, getters, allState) => {
  const authoritativeFiles = allState.diffs.diffFiles;

  return getters.allResolvableDiscussions
    .filter((d) => !d.resolved && d.active)
    .sort((a, b) => {
      let order = 0;

      if (!a.diff_file || !b.diff_file) {
        return order;
      }

      const authoritativeA = authoritativeFiles.find((source) =>
        match({ fileA: source, fileB: a.diff_file, mode: 'mr' }),
      );
      const authoritativeB = authoritativeFiles.find((source) =>
        match({ fileA: source, fileB: b.diff_file, mode: 'mr' }),
      );

      if (authoritativeA && authoritativeB) {
        order = authoritativeA.order - authoritativeB.order;
      }

      // Get the line numbers, to compare within the same file
      const aLines = [a.position.new_line, a.position.old_line];
      const bLines = [b.position.new_line, b.position.old_line];

      return order < 0 ||
        (order === 0 &&
          // .max() because one of them might be zero (if removed/added)
          Math.max(aLines[0], aLines[1]) < Math.max(bLines[0], bLines[1]))
        ? -1
        : 1;
    })
    .map((d) => d.id);
};

export const resolvedDiscussionCount = (state, getters) => {
  const resolvedMap = getters.resolvedDiscussionsById;

  return Object.keys(resolvedMap).length;
};

export const discussionTabCounter = (state) =>
  state.discussions.reduce(
    (acc, discussion) =>
      acc + discussion.notes.filter((note) => !note.system && !note.placeholder).length,
    0,
  );

// Returns the list of discussion IDs ordered according to given parameter
// @param {Boolean} diffOrder - is ordered by diff?
export const unresolvedDiscussionsIdsOrdered = (state, getters) => (diffOrder) => {
  if (diffOrder) {
    return getters.unresolvedDiscussionsIdsByDiff;
  }
  return getters.unresolvedDiscussionsIdsByDate;
};

// Checks if a given discussion is the last in the current order (diff or date)
// @param {Boolean} discussionId - id of the discussion
// @param {Boolean} diffOrder - is ordered by diff?
export const isLastUnresolvedDiscussion = (state, getters) => (discussionId, diffOrder) => {
  const idsOrdered = getters.unresolvedDiscussionsIdsOrdered(diffOrder);
  const lastDiscussionId = idsOrdered[idsOrdered.length - 1];

  return lastDiscussionId === discussionId;
};

export const findUnresolvedDiscussionIdNeighbor =
  (state, getters) =>
  ({ discussionId, diffOrder, step }) => {
    const diffIds = getters.unresolvedDiscussionsIdsOrdered(diffOrder);
    const dateIds = getters.unresolvedDiscussionsIdsOrdered(false);
    const ids = diffIds.length ? diffIds : dateIds;
    const index = ids.indexOf(discussionId) + step;

    if (index < 0 && step < 0) {
      return ids[ids.length - 1];
    }

    if (index === ids.length && step > 0) {
      return ids[0];
    }

    return ids[index];
  };

// Gets the ID of the discussion following the one provided, respecting order (diff or date)
// @param {Boolean} discussionId - id of the current discussion
// @param {Boolean} diffOrder - is ordered by diff?
export const nextUnresolvedDiscussionId = (state, getters) => (discussionId, diffOrder) =>
  getters.findUnresolvedDiscussionIdNeighbor({ discussionId, diffOrder, step: 1 });

export const previousUnresolvedDiscussionId = (state, getters) => (discussionId, diffOrder) =>
  getters.findUnresolvedDiscussionIdNeighbor({ discussionId, diffOrder, step: -1 });

// @param {Boolean} diffOrder - is ordered by diff?
export const firstUnresolvedDiscussionId = (state, getters) => (diffOrder) => {
  if (diffOrder) {
    return getters.unresolvedDiscussionsIdsByDiff[0];
  }
  return getters.unresolvedDiscussionsIdsByDate[0];
};

export const getDiscussion = (state) => (discussionId) =>
  state.discussions.find((discussion) => discussion.id === discussionId);

export const commentsDisabled = (state) => state.commentsDisabled;

export const suggestionsCount = (state, getters) =>
  Object.values(getters.notesById).filter((n) => n.suggestions?.length).length;

// eslint-disable-next-line max-params
export const hasDrafts = (state, getters, rootState, rootGetters) =>
  Boolean(rootGetters['batchComments/hasDrafts']);

export const getSuggestionsFilePaths = (state) => () =>
  state.batchSuggestionsInfo.reduce((acc, suggestion) => {
    const discussion = state.discussions.find((d) => d.id === suggestion.discussionId);

    if (acc.indexOf(discussion?.diff_file?.file_path) === -1) {
      acc.push(discussion.diff_file.file_path);
    }

    return acc;
  }, []);

export const getFetchDiscussionsConfig = (state, getters) => {
  const defaultConfig = { path: getters.getNotesDataByProp('discussionsPath') };

  const currentFilter =
    getters.getNotesDataByProp('notesFilter') || constants.DISCUSSION_FILTERS_DEFAULT_VALUE;

  if (
    doesHashExistInUrl(constants.NOTE_UNDERSCORE) &&
    currentFilter !== constants.DISCUSSION_FILTERS_DEFAULT_VALUE
  ) {
    return {
      ...defaultConfig,
      filter: constants.DISCUSSION_FILTERS_DEFAULT_VALUE,
      persistFilter: false,
    };
  }
  return defaultConfig;
};

export const allDiscussionsExpanded = (state) => {
  return state.discussions.every((discussion) => discussion.expanded);
};
