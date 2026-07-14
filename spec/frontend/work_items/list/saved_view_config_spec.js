import { buildInitialViewState } from '~/work_items/list/saved_view_config';
import { VIEW_MODE_LIST } from '~/work_items/constants';

describe('buildInitialViewState', () => {
  const savedView = {
    sort: 'CREATED_DESC',
    displaySettings: { viewMode: 'BOARD', hiddenMetadataKeys: ['labels'] },
  };
  const commonPreferences = { shouldOpenItemsInSidePanel: false };

  it('maps the saved view sort, view mode and display settings', () => {
    expect(buildInitialViewState({ savedView, commonPreferences })).toEqual({
      initialViewSortKey: 'CREATED_DESC',
      initialViewMode: 'BOARD',
      initialViewDisplaySettings: {
        commonPreferences: { shouldOpenItemsInSidePanel: false },
        namespacePreferences: { viewMode: 'BOARD', hiddenMetadataKeys: ['labels'] },
      },
    });
  });

  it('copies common preferences rather than referencing them', () => {
    const result = buildInitialViewState({ savedView, commonPreferences });

    expect(result.initialViewDisplaySettings.commonPreferences).not.toBe(commonPreferences);
  });

  it('falls back to default view mode and display settings when they are missing', () => {
    expect(
      buildInitialViewState({ savedView: { sort: 'CREATED_DESC' }, commonPreferences: {} }),
    ).toEqual({
      initialViewSortKey: 'CREATED_DESC',
      initialViewMode: VIEW_MODE_LIST,
      initialViewDisplaySettings: {
        commonPreferences: {},
        namespacePreferences: {},
      },
    });
  });

  it('falls back to defaults when the saved view is missing', () => {
    expect(buildInitialViewState({ savedView: null, commonPreferences: {} })).toEqual({
      initialViewSortKey: null,
      initialViewMode: VIEW_MODE_LIST,
      initialViewDisplaySettings: {
        commonPreferences: {},
        namespacePreferences: {},
      },
    });
  });
});
