import AjaxCache from '~/lib/utils/ajax_cache';
import { trimFirstCharOfLineContent } from '~/diffs/store/utils';
import { sprintf, __ } from '~/locale';

const REGEX_QUICK_ACTIONS = /^\/\w+.*$/gm;

export const findNoteObjectById = (notes, id) => notes.filter(n => n.id === id)[0];

export const getQuickActionText = note => {
  let text = __('Applying command');
  const quickActions = AjaxCache.get(gl.GfmAutoComplete.dataSources.commands) || [];

  const executedCommands = quickActions.filter(command => {
    const commandRegex = new RegExp(`/${command.name}`);
    return commandRegex.test(note);
  });

  if (executedCommands && executedCommands.length) {
    if (executedCommands.length > 1) {
      text = __('Applying multiple commands');
    } else {
      const commandDescription = executedCommands[0].description.toLowerCase();
      text = sprintf(__('Applying command to %{commandDescription}', { commandDescription }));
    }
  }

  return text;
};

export const hasQuickActions = note => REGEX_QUICK_ACTIONS.test(note);

export const stripQuickActions = note => note.replace(REGEX_QUICK_ACTIONS, '').trim();

export const prepareDiffLines = diffLines =>
  diffLines.map(line => ({ ...trimFirstCharOfLineContent(line) }));
