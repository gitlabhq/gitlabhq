import { flattenDeep, clone } from 'lodash';
import { match } from '~/diffs/utils/diff_file';
import { isInMRPage } from '~/lib/utils/common_utils';
import { doesHashExistInUrl } from '~/lib/utils/url_utility';
import { badgeState } from '~/merge_requests/components/merge_request_header.vue';
import { useBatchComments } from '~/batch_comments/store';
import * as constants from '../../constants';
import { collapseSystemNotes } from '../../stores/collapse_utils';

const getDraftComments = (drafts) => {
  return drafts
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

export function filteredDiscussions() {
  let discussionsInState = clone(this.discussions);
  // NOTE: not testing bc will be removed when backend is finished.

  if (this.noteableData.targetType === 'merge_request') {
    discussionsInState = discussionsInState.reduce((acc, discussion) => {
      if (hideActivity(this.mergeRequestFilters, discussion)) {
        return acc;
      }

      acc.push(discussion);

      return acc;
    }, []);
  }

  if (this.isTimelineEnabled) {
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

  discussionsInState = discussionsInState.concat(getDraftComments(useBatchComments().drafts));

  if (this.discussionSortOrder === constants.DESC) {
    discussionsInState = discussionsInState.reverse();
  }

  return discussionsInState;
}

export function getNotesData() {
  return this.notesData;
}

export function sortDirection() {
  return this.discussionSortOrder;
}

export function timelineEnabled() {
  return this.isTimelineEnabled;
}

export function getNotesDataByProp() {
  return (prop) => this.notesData[prop];
}

export function getNoteableData() {
  return this.noteableData;
}

export function getNoteableDataByProp() {
  return (prop) => this.noteableData[prop];
}

export function getBlockedByIssues() {
  return this.noteableData.blocked_by_issues;
}

export function userCanReply() {
  return Boolean(this.noteableData.current_user.can_create_note);
}

export function openState() {
  return isInMRPage() ? badgeState.state : this.noteableData.state;
}

export function getUserData() {
  return this.userData || {};
}

export function getUserDataByProp() {
  return (prop) => this.userData && this.userData[prop];
}

export function canUserAddIncidentTimelineEvents() {
  return Boolean(
    this.userData?.can_add_timeline_events &&
      this.noteableData.type === constants.NOTEABLE_TYPE_MAPPING.Incident,
  );
}

export function notesById() {
  return this.discussions.reduce((acc, note) => {
    note.notes.every((n) => Object.assign(acc, { [n.id]: n }));
    return acc;
  }, {});
}

export function noteableType() {
  const { ISSUE_NOTEABLE_TYPE, MERGE_REQUEST_NOTEABLE_TYPE, EPIC_NOTEABLE_TYPE } = constants;

  if (this.noteableData.noteableType === EPIC_NOTEABLE_TYPE) {
    return EPIC_NOTEABLE_TYPE;
  }

  return this.noteableData.merge_params ? MERGE_REQUEST_NOTEABLE_TYPE : ISSUE_NOTEABLE_TYPE;
}

const reverseNotes = (array) => array.slice(0).reverse();

const isLastNote = (note, state) =>
  !note.system && state.userData && note.author && note.author.id === state.userData.id;

export function getCurrentUserLastNote() {
  return flattenDeep(reverseNotes(this.discussions).map((note) => reverseNotes(note.notes))).find(
    (el) => isLastNote(el, this),
  );
}

export function getDiscussionLastNote() {
  return (discussion) => reverseNotes(discussion.notes).find((el) => isLastNote(el, this));
}

export function showJumpToNextDiscussion() {
  return (mode = 'discussion') => {
    const orderedDiffs =
      mode !== 'discussion'
        ? this.unresolvedDiscussionsIdsByDiff
        : this.unresolvedDiscussionsIdsByDate;

    return orderedDiffs.length > 1;
  };
}

export function isDiscussionResolved() {
  return (discussionId) => this.resolvedDiscussionsById[discussionId] !== undefined;
}

export function allResolvableDiscussions() {
  return this.discussions.filter((d) => !d.individual_note && d.resolvable);
}

export function resolvedDiscussionsById() {
  const map = {};

  this.discussions
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
}

export function unresolvedDiscussionsIdsByDate() {
  return this.allResolvableDiscussions
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
}

export function unresolvedDiscussionsIdsByDiff() {
  // WARNING: never use this in regular code, this is only needed to avoid circular dependencies
  const authoritativeFiles = this.tryStore('legacyDiffs').diffFiles;

  return this.allResolvableDiscussions
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
}

export function resolvedDiscussionCount() {
  const resolvedMap = this.resolvedDiscussionsById;

  return Object.keys(resolvedMap).length;
}

export function discussionTabCounter() {
  return this.discussions.reduce(
    (acc, discussion) =>
      acc + discussion.notes.filter((note) => !note.system && !note.placeholder).length,
    0,
  );
}

export function unresolvedDiscussionsIdsOrdered() {
  return (diffOrder) => {
    if (diffOrder) {
      return this.unresolvedDiscussionsIdsByDiff;
    }
    return this.unresolvedDiscussionsIdsByDate;
  };
}

export function isLastUnresolvedDiscussion() {
  return (discussionId, diffOrder) => {
    const idsOrdered = this.unresolvedDiscussionsIdsOrdered(diffOrder);
    const lastDiscussionId = idsOrdered[idsOrdered.length - 1];

    return lastDiscussionId === discussionId;
  };
}

export function findUnresolvedDiscussionIdNeighbor() {
  return ({ discussionId, diffOrder, step }) => {
    const diffIds = this.unresolvedDiscussionsIdsOrdered(diffOrder);
    const dateIds = this.unresolvedDiscussionsIdsOrdered(false);
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
}

export function nextUnresolvedDiscussionId() {
  return (discussionId, diffOrder) =>
    this.findUnresolvedDiscussionIdNeighbor({ discussionId, diffOrder, step: 1 });
}

export function previousUnresolvedDiscussionId() {
  return (discussionId, diffOrder) =>
    this.findUnresolvedDiscussionIdNeighbor({ discussionId, diffOrder, step: -1 });
}

export function firstUnresolvedDiscussionId() {
  return (diffOrder) => {
    if (diffOrder) {
      return this.unresolvedDiscussionsIdsByDiff[0];
    }
    return this.unresolvedDiscussionsIdsByDate[0];
  };
}

export function getDiscussion() {
  return (discussionId) => this.discussions.find((discussion) => discussion.id === discussionId);
}

export function suggestionsCount() {
  return Object.values(this.notesById).filter((n) => n.suggestions?.length).length;
}

export function hasDrafts() {
  return Boolean(useBatchComments().hasDrafts);
}

export function getSuggestionsFilePaths() {
  return () =>
    this.batchSuggestionsInfo.reduce((acc, suggestion) => {
      const discussion = this.discussions.find((d) => d.id === suggestion.discussionId);

      if (acc.indexOf(discussion?.diff_file?.file_path) === -1) {
        acc.push(discussion.diff_file.file_path);
      }

      return acc;
    }, []);
}

export function getFetchDiscussionsConfig() {
  const defaultConfig = { path: this.getNotesDataByProp('discussionsPath') };

  const currentFilter =
    this.getNotesDataByProp('notesFilter') || constants.DISCUSSION_FILTERS_DEFAULT_VALUE;

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
}

export function allDiscussionsExpanded() {
  return this.discussions.every((discussion) => discussion.expanded);
}
