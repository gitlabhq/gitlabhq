import * as mutationTypes from '~/ide/stores/mutation_types';
import terminalModule from '../modules/terminal';

function getPathsFromData(el) {
  return {
    webTerminalSvgPath: el.dataset.webTerminalSvgPath,
    webTerminalHelpPath: el.dataset.webTerminalHelpPath,
    webTerminalConfigHelpPath: el.dataset.webTerminalConfigHelpPath,
    webTerminalRunnersHelpPath: el.dataset.webTerminalRunnersHelpPath,
  };
}

export default function createTerminalPlugin(el) {
  return (store) => {
    store.registerModule('terminal', terminalModule());

    store.dispatch('terminal/setPaths', getPathsFromData(el));

    store.subscribe(({ type }) => {
      if (type === mutationTypes.SET_BRANCH_WORKING_REFERENCE) {
        store.dispatch('terminal/init');
      }
    });
  };
}
