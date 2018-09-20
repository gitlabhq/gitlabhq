import AjaxCache from '~/lib/utils/ajax_cache';

const REGEX_QUICK_ACTIONS = /^\/\w+.*$/gm;
const REGEX_NOTE_HASH = /^note_/;
const REGEX_DISCUSSION_HASH = /^discussion_/;

export const findNoteObjectById = (notes, id) => notes.filter(n => n.id === id)[0];

export const getQuickActionText = note => {
  let text = 'Applying command';
  const quickActions = AjaxCache.get(gl.GfmAutoComplete.dataSources.commands) || [];

  const executedCommands = quickActions.filter(command => {
    const commandRegex = new RegExp(`/${command.name}`);
    return commandRegex.test(note);
  });

  if (executedCommands && executedCommands.length) {
    if (executedCommands.length > 1) {
      text = 'Applying multiple commands';
    } else {
      const commandDescription = executedCommands[0].description.toLowerCase();
      text = `Applying command to ${commandDescription}`;
    }
  }

  return text;
};

export const reduceDiscussionsToLineCodes = selectedDiscussions =>
  selectedDiscussions.reduce((acc, note) => {
    if (note.diff_discussion && note.line_code) {
      // For context about line notes: there might be multiple notes with the same line code
      const items = acc[note.line_code] || [];
      items.push(note);

      Object.assign(acc, { [note.line_code]: items });
    }
    return acc;
  }, {});

export const hasQuickActions = note => REGEX_QUICK_ACTIONS.test(note);

export const stripQuickActions = note => note.replace(REGEX_QUICK_ACTIONS, '').trim();

/**
 * Create a predicate function to check if a discussion matches the given hash
 *
 * Based on the format of the hash, a different predicate is returned:
 *
 * | Format         | Rule                                        |
 * |----------------|---------------------------------------------|
 * | `note_*`       | match if discussion has a note with the id  |
 * | `discussion_*` | match if discussion has the given id        |
 * | `*`            | match if discussion has the given line_code |
 *
 * Example:
 *
```
const hash = getLocationHash();

return discussions.filter(whereDiscussionMatchesHash(hash));
```
 *
 * @param {String} hash - A string that represents a discussion selector
 * @returns {(discussion: any) => Boolean} A predicate that matches discussions against the hash
 */
export const whereDiscussionMatchesHash = hash => {
  if (!hash) {
    return () => false;
  } else if (hash.match(REGEX_NOTE_HASH)) {
    const noteId = hash.replace(REGEX_NOTE_HASH, '');

    return discussion => discussion.notes.some(note => String(note.id) === noteId);
  } else if (hash.match(REGEX_DISCUSSION_HASH)) {
    const discussionId = hash.replace(REGEX_DISCUSSION_HASH, '');

    return discussion => discussion.id === discussionId;
  }

  return discussion => discussion.line_code === hash;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
