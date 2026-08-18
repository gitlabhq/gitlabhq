import { marked } from 'marked';
import markedBidi from 'marked-bidi';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { sprintf } from '~/locale';
import { UPDATE_COMMENT_FORM, COMMENT_FORM } from './i18n';

/**
 * Tracks snowplow event when User toggles timeline view
 * @param {Boolean} enabled that will be send as a property for the event
 */
export const trackToggleTimelineView = (enabled) => ({
  category: 'Incident Management', // eslint-disable-line @gitlab/require-i18n-strings
  action: 'toggle_incident_comments_into_timeline_view',
  label: 'Status', // eslint-disable-line @gitlab/require-i18n-strings
  property: enabled,
});

marked.use(markedBidi());

export const renderMarkdown = (rawMarkdown) => {
  return sanitize(marked(rawMarkdown), markdownConfig);
};

export const getNoteFormErrorMessages = (response, messages) => {
  const { error: errorMessage, defaultError: defaultErrorMessage } = messages || COMMENT_FORM;
  if (response && response.status === HTTP_STATUS_UNPROCESSABLE_ENTITY) {
    if (response.data?.quick_actions_status?.error_messages?.length) {
      return response.data?.quick_actions_status.error_messages;
    }

    const errors = response.data?.errors;
    if (errorMessage && errors) {
      return [sprintf(errorMessage, { reason: errors.toLowerCase() }, false)];
    }
  }

  return [defaultErrorMessage || COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK];
};

export const updateNoteErrorMessage = (e) => {
  const errors = e?.response?.data?.errors;

  if (errors) {
    return sprintf(UPDATE_COMMENT_FORM.error, { reason: errors.toLowerCase() }, false);
  }

  return UPDATE_COMMENT_FORM.defaultError;
};

/**
 * Whether a system note should render with the styled GitLab Duo treatment
 * (avatar + progress spinner) rather than as a plain system note.
 *
 * Two distinct notes qualify:
 * - Duo mention notes (action `duo_mention_started`): identified by the presence
 *   of `duo_session_status`, which EE::NoteEntity serializes only for them. This
 *   covers both the @GitLabDuo bot and the @duo-developer service account.
 * - The Duo Code Review progress note (action `duo_code_review_started`): it has
 *   no `duo_session_status`, so it is matched via its bot author's user_type.
 *   `duo_code_review_bot` is the dedicated internal GitLab Duo user (see
 *   Users::Internal); it is the author's account type, not a per-note flag.
 *
 * The bot also authors `cross_reference` notes ("mentioned in ...") from its
 * review summary, which must stay plain, so the author branch excludes the
 * `comment-dots` icon that only `cross_reference` produces.
 */
export const shouldRenderAsDuoSystemNote = (note) =>
  Boolean(note?.system) &&
  (note.duo_session_status !== undefined ||
    (note.author?.user_type === 'duo_code_review_bot' &&
      note.system_note_icon_name !== 'comment-dots'));

const matchesAuthor = (candidate, authorId) =>
  shouldRenderAsDuoSystemNote(candidate) && candidate.author?.id === authorId;

/**
 * Finds the Duo "thinking" note that an incoming reply should remove, matched by
 * author so a human comment during the flow never removes it early.
 *
 * Looks in the reply's own discussion first (the @mention path, where the note
 * lives in the reply's thread), then falls back to all discussions (the Duo Code
 * Review path, where the note is top-level and the reply lands in an unloaded
 * diff discussion). Callers must pass the full discussions list.
 *
 * @param {Array} incomingNotes - Notes received from the poll endpoint.
 * @param {Array} discussions   - Current discussions to search within.
 * @returns {Object|null} The started note to remove, or null if none found.
 */
export const findStartedNoteForReply = (incomingNotes, discussions) => {
  for (const note of incomingNotes) {
    if (note.system || note.author?.id == null) continue;

    const authorId = note.author.id;

    // Prefer the reply's own discussion, then fall back to the others.
    const ownDiscussion = discussions.find((d) => d.id === note.discussion_id);
    const startedInOwn = ownDiscussion?.notes?.find((n) => matchesAuthor(n, authorId));
    if (startedInOwn) return startedInOwn;

    for (const discussion of discussions) {
      if (discussion === ownDiscussion) continue;
      const startedNote = discussion.notes?.find((n) => matchesAuthor(n, authorId));
      if (startedNote) return startedNote;
    }
  }

  return null;
};

export const isSlashCommand = (message) => {
  const trimmedMessage = message
    ?.split('\n')
    .filter((line) => line.trim() !== '')
    .join('\n');
  return trimmedMessage?.startsWith('/') || false;
};
