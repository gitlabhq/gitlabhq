import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { redirectTo, updateHistory } from '~/lib/utils/url_utility';
import AbuseReportsFilteredSearchBar from '~/admin/abuse_reports/components/abuse_reports_filtered_search_bar.vue';
import {
  FILTERED_SEARCH_TOKENS,
  FILTERED_SEARCH_TOKEN_USER,
  FILTERED_SEARCH_TOKEN_STATUS,
} from '~/admin/abuse_reports/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    __esModule: true,
    ...urlUtility,
    redirectTo: jest.fn(),
    updateHistory: jest.fn(),
  };
});

describe('AbuseReportsFilteredSearchBar', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AbuseReportsFilteredSearchBar);
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  beforeEach(() => {
    setWindowLocation('https://localhost');
  });

  it('passes correct props to `FilteredSearchBar` component', () => {
    createComponent();

    expect(findFilteredSearchBar().props()).toMatchObject({
      namespace: 'abuse_reports',
      recentSearchesStorageKey: 'abuse_reports',
      searchInputPlaceholder: 'Filter reports',
      tokens: FILTERED_SEARCH_TOKENS,
    });
  });

  it('sets status=open query when there is no initial status query', () => {
    createComponent();

    expect(updateHistory).toHaveBeenCalledWith({
      url: 'https://localhost/?status=open',
      replace: true,
    });

    expect(findFilteredSearchBar().props('initialFilterValue')).toMatchObject([
      {
        type: FILTERED_SEARCH_TOKEN_STATUS.type,
        value: { data: 'open', operator: '=' },
      },
    ]);
  });

  it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
    setWindowLocation('?status=closed&user=mr_abuser');

    createComponent();

    expect(findFilteredSearchBar().props('initialFilterValue')).toMatchObject([
      {
        type: FILTERED_SEARCH_TOKEN_USER.type,
        value: { data: 'mr_abuser', operator: '=' },
      },
      {
        type: FILTERED_SEARCH_TOKEN_STATUS.type,
        value: { data: 'closed', operator: '=' },
      },
    ]);
  });

  describe('when filter bar is submitted', () => {
    it('redirects with user query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_USER.type, value: { data: 'mr_abuser', operator: '=' } },
      ]);

      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?user=mr_abuser');
    });

    it('redirects with status query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_STATUS.type, value: { data: 'open', operator: '=' } },
      ]);

      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?status=open');
    });

    it('ignores search query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_STATUS.type, value: { data: 'open', operator: '=' } },
        { type: FILTERED_SEARCH_TERM, value: { data: 'ignored' } },
      ]);

      expect(redirectTo).toHaveBeenCalledWith('https://localhost/?status=open');
    });
  });
});
