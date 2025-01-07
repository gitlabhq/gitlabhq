import { isEmpty } from 'lodash';
import { createAlert } from '~/alert';
import { scrollToElement } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { FILE_DIFF_POSITION_TYPE } from '~/diffs/constants';
import { updateNoteErrorMessage } from '~/notes/utils';
import { CHANGES_TAB, DISCUSSION_TAB, SHOW_TAB } from '../constants';
import service from '../services/drafts_service';
import * as types from '../stores/modules/batch_comments/mutation_types';

export function saveDraft(draft) {
  return this.tryStore('legacyNotes').saveNote({ ...draft, isDraft: true });
}

export function addDraftToDiscussion({ endpoint, data }) {
  return service
    .addDraftToDiscussion(endpoint, data)
    .then((res) => res.data)
    .then((res) => {
      this[types.ADD_NEW_DRAFT](res);
      return res;
    })
    .catch((e) => {
      throw e.response;
    });
}

export function createNewDraft({ endpoint, data }) {
  return service
    .createNewDraft(endpoint, data)
    .then((res) => res.data)
    .then((res) => {
      this[types.ADD_NEW_DRAFT](res);

      if (res.position?.position_type === FILE_DIFF_POSITION_TYPE) {
        this.tryStore('legacyDiffs').addDraftToFile({ filePath: res.file_path, draft: res });
      }

      return res;
    })
    .catch((e) => {
      throw e.response;
    });
}

export function deleteDraft(draft) {
  return service
    .deleteDraft(this.getNotesData.draftsPath, draft.id)
    .then(() => {
      this[types.DELETE_DRAFT](draft.id);
    })
    .catch(() =>
      createAlert({
        message: __('An error occurred while deleting the comment'),
      }),
    );
}

export function fetchDrafts() {
  return service
    .fetchDrafts(this.getNotesData.draftsPath)
    .then((res) => res.data)
    .then((data) => this[types.SET_BATCH_COMMENTS_DRAFTS](data))
    .then(() => {
      this.drafts.forEach((draft) => {
        if (draft.position?.position_type === FILE_DIFF_POSITION_TYPE) {
          this.tryStore('legacyDiffs').addDraftToFile({ filePath: draft.file_path, draft });
        } else if (!draft.line_code) {
          this.tryStore('legacyNotes').convertToDiscussion(draft.discussion_id);
        }
      });
    })
    .catch(() =>
      createAlert({
        message: __('An error occurred while fetching pending comments'),
      }),
    );
}

export function publishSingleDraft(draftId) {
  this[types.REQUEST_PUBLISH_DRAFT](draftId);

  service
    .publishDraft(this.getNotesData.draftsPublishPath, draftId)
    .then(() => this[types.RECEIVE_PUBLISH_DRAFT_SUCCESS](draftId))
    .catch(() => this[types.RECEIVE_PUBLISH_DRAFT_ERROR](draftId));
}

export function publishReview(noteData = {}) {
  this[types.REQUEST_PUBLISH_REVIEW]();

  return service
    .publish(this.getNotesData.draftsPublishPath, noteData)
    .then(() => this[types.RECEIVE_PUBLISH_REVIEW_SUCCESS]())
    .catch((e) => {
      this[types.RECEIVE_PUBLISH_REVIEW_ERROR]();

      throw e.response;
    });
}

export function updateDraft({
  note,
  noteText,
  resolveDiscussion,
  position,
  flashContainer,
  callback,
  errorCallback,
}) {
  const params = {
    draftId: note.id,
    note: noteText,
    resolveDiscussion,
  };
  // Stringifying an empty object yields `{}` which breaks graphql queries
  // https://gitlab.com/gitlab-org/gitlab/-/issues/298827
  if (!isEmpty(position)) params.position = JSON.stringify(position);

  return service
    .update(this.getNotesData.draftsPath, params)
    .then((res) => res.data)
    .then((data) => this[types.RECEIVE_DRAFT_UPDATE_SUCCESS](data))
    .then(callback)
    .catch((e) => {
      createAlert({
        message: updateNoteErrorMessage(e),
        parent: flashContainer,
      });

      errorCallback();
    });
}

export function scrollToDraft(draft) {
  const discussion =
    draft.discussion_id && this.tryStore('legacyNotes').getDiscussion(draft.discussion_id);
  const tab =
    draft.file_hash || (discussion && discussion.diff_discussion) ? CHANGES_TAB : SHOW_TAB;
  const tabEl = tab === CHANGES_TAB ? CHANGES_TAB : DISCUSSION_TAB;
  const draftID = `note_${draft.id}`;
  const el = document.querySelector(`#${tabEl} #${draftID}`);

  window.location.hash = draftID;

  if (window.mrTabs.currentAction !== tab) {
    window.mrTabs.tabShown(tab);
  }

  const { file_path: filePath } = draft;

  if (filePath) {
    this.tryStore('legacyDiffs').setFileCollapsedAutomatically({ filePath, collapsed: false });
  }

  if (discussion) {
    this.tryStore('legacyNotes').expandDiscussion({ discussionId: discussion.id });
  }

  if (el) {
    setTimeout(() => scrollToElement(el.closest('.draft-note-component')));
  }
}

export function expandAllDiscussions() {
  return this.drafts
    .filter((draft) => draft.discussion_id)
    .forEach((draft) => {
      this.tryStore('legacyNotes').expandDiscussion({ discussionId: draft.discussion_id });
    });
}

export function toggleResolveDiscussion(draftId) {
  this[types.TOGGLE_RESOLVE_DISCUSSION](draftId);
}

export function clearDrafts() {
  return this[types.CLEAR_DRAFTS]();
}

export function discardDrafts() {
  return service
    .discard(this.getNotesData.draftsDiscardPath)
    .then(() => {
      this[types.CLEAR_DRAFTS]();
    })
    .catch((error) =>
      createAlert({
        captureError: true,
        error,
        message: __('An error occurred while discarding your review. Please try again.'),
      }),
    );
}
