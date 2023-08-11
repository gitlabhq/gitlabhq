/**
 * Provides global values to the admin runners app.
 *
 * @param {Object} `data-` HTML attributes of the mounting point
 * @returns An object with properties to use provide/inject of the root app.
 * See EE version
 */
export const provide = (elDataset) => {
  const {
    runnerInstallHelpPage,
    onlineContactTimeoutSecs,
    staleTimeoutSecs,
    tagSuggestionsPath,
  } = elDataset;

  return {
    runnerInstallHelpPage,
    onlineContactTimeoutSecs,
    staleTimeoutSecs,
    tagSuggestionsPath,
  };
};
