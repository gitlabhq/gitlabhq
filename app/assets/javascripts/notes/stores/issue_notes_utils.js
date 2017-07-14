import AjaxCache from '~/lib/utils/ajax_cache';

const REGEX_QUICK_ACTIONS = /^\/\w+.*$/gm;

export default {
  getQuickActionText(note) {
    let text = 'Applying command';
    const quickActions = AjaxCache.get(gl.GfmAutoComplete.dataSources.commands);

    const executedCommands = quickActions.filter((command) => {
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
  },
  hasQuickActions(note) {
    return REGEX_QUICK_ACTIONS.test(note);
  },
  stripQuickActions(note) {
    return note.replace(REGEX_QUICK_ACTIONS, '').trim();
  },
};
