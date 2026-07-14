import { VIEW_MODE_LIST } from '~/work_items/constants';

// Maps a loaded saved view into the component's "initial view" baseline (the
// non-filter-token fields). Tokens are resolved separately by the caller
// because that conversion depends on the available search tokens.
export const buildInitialViewState = ({ savedView, commonPreferences }) => ({
  initialViewSortKey: savedView?.sort ?? null,
  initialViewMode: savedView?.displaySettings?.viewMode ?? VIEW_MODE_LIST,
  initialViewDisplaySettings: {
    commonPreferences: { ...commonPreferences },
    namespacePreferences: savedView?.displaySettings ?? {},
  },
});
