import * as mutationTypes from '~/ide/stores/mutation_types';
import terminalModule from '../modules/terminal';

function getPathsFromData(el) {
  return {
    webTerminalSvgPath: el.dataset.eeWebTerminalSvgPath,
    webTerminalHelpPath: el.dataset.eeWebTerminalHelpPath,
    webTerminalConfigHelpPath: el.dataset.eeWebTerminalConfigHelpPath,
    webTerminalRunnersHelpPath: el.dataset.eeWebTerminalRunnersHelpPath,
  };
}

export default function createTerminalPlugin(el) {
  return store => {
    store.registerModule('terminal', terminalModule());

    store.dispatch('terminal/setPaths', getPathsFromData(el));

    store.subscribe(({ type }) => {
      if (type === mutationTypes.SET_BRANCH_WORKING_REFERENCE) {
        store.dispatch('terminal/init');
      }
    });
  };
}
