import { GlTabsBehavior, HISTORY_TYPE_HASH } from '~/tabs';
import { ACTIVE_PANEL_CLASS } from '~/tabs/constants';
import { HIDE_CLASS, SEARCH_TERM_CHANGED_EVENT } from '~/search_settings/constants';

// Every pane belongs to the single preferences form, so this reveals the pane holding a field
// that fails native validation, and shows every pane while the settings search is active.
export const initPreferencesTabs = ({ tabsEl, formEl }) => {
  const tabs = new GlTabsBehavior(tabsEl, { history: HISTORY_TYPE_HASH });
  const tabsWrapperEl = tabsEl.closest('.gl-tabs-wrapper') ?? tabsEl;

  // `invalid` does not bubble, so listen during the capture phase.
  formEl.addEventListener('invalid', ({ target }) => tabs.revealElement(target), true);

  document.addEventListener(SEARCH_TERM_CHANGED_EVENT, ({ detail }) => {
    const isSearching = detail.searchTerm.length > 0;

    tabsWrapperEl.classList.toggle(HIDE_CLASS, isSearching);
    tabs.tabs.forEach((tab) => {
      tabs
        .getPanelForTab(tab)
        .classList.toggle(ACTIVE_PANEL_CLASS, isSearching || tab === tabs.activeTab);
    });
  });

  return tabs;
};
