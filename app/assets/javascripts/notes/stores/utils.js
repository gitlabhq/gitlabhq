import { trimFirstCharOfLineContent } from '~/diffs/store/utils'; // eslint-disable-line import/no-deprecated
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import AjaxCache from '~/lib/utils/ajax_cache';
import { sprintf, __ } from '~/locale';

// factory function because global flag makes RegExp stateful
const createQuickActionsRegex = () => /^\/\w+.*$/gm;

export const findNoteObjectById = (notes, id) => notes.filter((n) => n.id === id)[0];

export const getQuickActionText = (note) => {
  let text = __('Applying command');
  const quickActions = AjaxCache.get(gl.GfmAutoComplete.dataSources.commands) || [];

  const executedCommands = quickActions.filter((command) => {
    const commandRegex = new RegExp(`/${command.name}`);
    return commandRegex.test(note);
  });

  if (executedCommands && executedCommands.length) {
    if (executedCommands.length > 1) {
      text = __('Applying multiple commands');
    } else {
      const commandDescription = executedCommands[0].description.toLowerCase();
      text = sprintf(__('Applying command to %{commandDescription}'), { commandDescription });
    }
  }

  return text;
};

export const hasQuickActions = (note) => createQuickActionsRegex().test(note);

export const stripQuickActions = (note) => note.replace(createQuickActionsRegex(), '').trim();

export const prepareDiffLines = (diffLines) =>
  diffLines.map((line) => ({ ...trimFirstCharOfLineContent(line) })); // eslint-disable-line import/no-deprecated

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);
