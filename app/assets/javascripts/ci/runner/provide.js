/**
 * Provides global values to the runners app.
 *
 *  - admin_runners/index.js and
 *  - group_runners/index.js
 *
 * Overridden in EE.
 *
 * @param {Object} `data-` HTML attributes of the mounting point
 * @returns An object with properties to use provide/inject of the EE root app.
 */
export const runnersAppProvide = (elDataset) => {
  const { runnerInstallHelpPage, onlineContactTimeoutSecs, staleTimeoutSecs } = elDataset;

  return {
    runnerInstallHelpPage,
    onlineContactTimeoutSecs: parseInt(onlineContactTimeoutSecs, 10),
    staleTimeoutSecs: parseInt(staleTimeoutSecs, 10),
  };
};
