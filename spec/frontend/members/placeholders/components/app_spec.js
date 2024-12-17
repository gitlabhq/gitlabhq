import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { GlTab, GlTabs, GlModal, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import PlaceholdersTabApp from '~/members/placeholders/components/app.vue';
import CsvUploadModal from '~/members/placeholders/components/csv_upload_modal.vue';
import KeepAllAsPlaceholderModal from '~/members/placeholders/components/keep_all_as_placeholder_modal.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  FILTERED_SEARCH_TERM,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import setWindowLocation from 'helpers/set_window_location_helper';

import {
  PLACEHOLDER_STATUS_FAILED,
  PLACEHOLDER_STATUS_REASSIGNING,
  PLACEHOLDER_USER_STATUS,
  PLACEHOLDER_SORT_STATUS_ASC,
  PLACEHOLDER_SORT_SOURCE_NAME_DESC,
  PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER,
} from '~/import_entities/import_groups/constants';
import { mockSourceUsersQueryResponse, mockSourceUsers, pagination } from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);
jest.mock('~/alert');

describe('PlaceholdersTabApp', () => {
  let wrapper;
  let store;
  let mockApollo;

  const sourceUsersQueryHandler = jest.fn().mockResolvedValue(mockSourceUsersQueryResponse());
  const $toast = {
    show: jest.fn(),
  };

  const mockGroup = {
    path: 'imported-group',
    name: 'Imported group',
    id: 1,
  };

  const createComponent = ({
    queryHandler = sourceUsersQueryHandler,
    mountFn = shallowMountExtended,
    provide = {},
  } = {}) => {
    store = new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.placeholder]: {
          namespaced: true,
          state: {
            pagination,
          },
        },
      },
    });

    mockApollo = createMockApollo([[importSourceUsersQuery, queryHandler]]);

    wrapper = mountFn(PlaceholdersTabApp, {
      apolloProvider: mockApollo,
      store,
      provide: {
        group: mockGroup,
        reassignmentCsvPath: 'foo/bar',
        ...provide,
      },
      mocks: { $toast },
      stubs: {
        GlTabs: stubComponent(GlTabs, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
        GlTab,
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabAt = (index) => wrapper.findAllComponents(GlTab).at(index);
  const findUnassignedTable = () => wrapper.findByTestId('placeholders-table-unassigned');
  const findReassignedTable = () => wrapper.findByTestId('placeholders-table-reassigned');
  const findReassignCsvButton = () => wrapper.findByTestId('reassign-csv-button');
  const findCsvModal = () => wrapper.findComponent(CsvUploadModal);
  const findKeepAllAsPlaceholderButton = () =>
    wrapper.findByTestId('keep-all-as-placeholder-button');
  const findKeepAllAsPlaceholderModal = () => wrapper.findComponent(KeepAllAsPlaceholderModal);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('filter, search and sort', () => {
    const filterByFailedStatusToken = { type: TOKEN_TYPE_STATUS, value: { data: 'failed' } };
    const filterByReassigningStatusToken = {
      type: TOKEN_TYPE_STATUS,
      value: { data: 'reassignment_in_progress' },
    };
    const searchTerm = 'source user 1';
    const searchTokens = [
      { type: FILTERED_SEARCH_TERM, value: { data: searchTerm } },
      { type: FILTERED_SEARCH_TERM, value: { data: '' } },
    ];

    it('renders FilteredSearchBar', () => {
      createComponent();

      expect(findFilteredSearchBar().exists()).toBe(true);
    });

    describe('without initial search query', () => {
      beforeEach(() => {
        createComponent();
      });

      it('updates URL on filter by status', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', [filterByFailedStatusToken]);
        await nextTick();

        expect(findUnassignedTable().props('queryStatuses')).toEqual([PLACEHOLDER_STATUS_FAILED]);
        expect(window.location.search).toBe(`?tab=placeholders&subtab=awaiting&status=failed`);
      });

      it('updates URL on search', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', searchTokens);
        await nextTick();

        expect(findUnassignedTable().props('querySearch')).toBe(searchTerm);
        expect(window.location.search).toBe(
          `?tab=placeholders&subtab=awaiting&search=source+user+1`,
        );
      });
    });

    describe('with status, search and sort queries present on load', () => {
      beforeEach(() => {
        setWindowLocation('?status=failed&search=foo&sort=STATUS_ASC');
        createComponent();
      });

      it('shows the "Unassigned" tab', () => {
        expect(findTabs().props('value')).toBe(0);
      });

      it('passes props to table', () => {
        expect(findUnassignedTable().props()).toMatchObject({
          querySearch: 'foo',
          queryStatuses: [PLACEHOLDER_STATUS_FAILED],
          querySort: PLACEHOLDER_SORT_STATUS_ASC,
        });
      });

      it('passes the correct sort to FilteredSearchBar', () => {
        expect(findFilteredSearchBar().props('initialSortBy')).toBe('STATUS_ASC');
      });

      it('updates URL on new filter and search', async () => {
        findFilteredSearchBar().vm.$emit('onFilter', [
          filterByReassigningStatusToken,
          ...searchTokens,
        ]);
        await nextTick();

        expect(findUnassignedTable().props()).toMatchObject({
          querySearch: searchTerm,
          queryStatuses: [PLACEHOLDER_STATUS_REASSIGNING],
        });
        expect(window.location.search).toBe(
          `?tab=placeholders&subtab=awaiting&status=reassignment_in_progress&search=source+user+1&sort=STATUS_ASC`,
        );
      });

      it('updates URL on new sort', async () => {
        findFilteredSearchBar().vm.$emit('onSort', 'SOURCE_NAME_DESC');
        await nextTick();

        expect(findUnassignedTable().props('querySort')).toBe(PLACEHOLDER_SORT_SOURCE_NAME_DESC);
        expect(window.location.search).toBe(
          `?tab=placeholders&subtab=awaiting&status=failed&search=foo&sort=SOURCE_NAME_DESC`,
        );
        expect(findFilteredSearchBar().props('initialSortBy')).toBe('SOURCE_NAME_DESC');
      });
    });

    describe('with reassigned status present on load', () => {
      beforeEach(() => {
        setWindowLocation('?status=keep_as_placeholder&search=foo&sort=STATUS_ASC');
        createComponent();
      });

      it('shows the "Reassigned" tab', () => {
        expect(findTabs().props('value')).toBe(1);
      });

      it('passes props to reassigned table', () => {
        expect(findReassignedTable().props()).toMatchObject({
          querySearch: 'foo',
          queryStatuses: [PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER],
          querySort: PLACEHOLDER_SORT_STATUS_ASC,
        });
      });
    });
  });

  it('renders an alert', () => {
    createComponent();

    expect(findAlert().exists()).toBe(true);
  });

  it('renders tabs', () => {
    createComponent();

    expect(findTabs().exists()).toBe(true);
  });

  it('renders tab titles with counts', async () => {
    createComponent();
    await nextTick();

    expect(findTabAt(0).text()).toBe(
      `Awaiting reassignment ${pagination.awaitingReassignmentItems}`,
    );
    expect(findTabAt(1).text()).toBe(`Reassigned ${pagination.reassignedItems}`);
  });

  describe('on table "confirm" event', () => {
    const mockSourceUser = mockSourceUsers[1];

    beforeEach(async () => {
      createComponent();
      await nextTick();

      findUnassignedTable().vm.$emit('confirm', mockSourceUser);
      await nextTick();
    });

    it('updates tab counts', () => {
      expect(findTabAt(0).text()).toBe(
        `Awaiting reassignment ${pagination.awaitingReassignmentItems - 1}`,
      );
      expect(findTabAt(1).text()).toBe(`Reassigned ${pagination.reassignedItems + 1}`);
    });

    it('shows toast', () => {
      expect($toast.show).toHaveBeenCalledWith(
        'Placeholder Placeholder 2 (@placeholder_2) was kept as a placeholder.',
      );
    });
  });

  describe('passes the correct queryStatuses to PlaceholdersTable', () => {
    it('awaiting Reassignment - when the url includes the query param failed', () => {
      setWindowLocation(`?status=failed`);
      createComponent();

      const placeholdersTable = findUnassignedTable();
      expect(placeholdersTable.props()).toMatchObject({
        queryStatuses: [PLACEHOLDER_STATUS_FAILED],
      });
    });

    it('awaiting Reassignment - when the url does not include query param', () => {
      createComponent();

      const placeholdersTable = findUnassignedTable();
      expect(placeholdersTable.props()).toMatchObject({
        queryStatuses: PLACEHOLDER_USER_STATUS.UNASSIGNED,
      });
    });

    it('reassigned', () => {
      setWindowLocation(`?tab=placeholders&subtab=reassigned`);
      createComponent();

      const placeholdersTable = findReassignedTable();
      expect(placeholdersTable.props()).toMatchObject({
        reassigned: true,
        queryStatuses: PLACEHOLDER_USER_STATUS.REASSIGNED,
      });
    });
  });

  describe('reassign CSV button', () => {
    describe('when the feature flag is enabled', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            glFeatures: { importerUserMappingReassignmentCsv: true },
          },
          mountFn: mountExtended,
        });
      });

      it('renders the button and the modal', () => {
        expect(findReassignCsvButton().exists()).toBe(true);
        expect(findCsvModal().exists()).toBe(true);
      });

      it('shows modal when button is clicked', async () => {
        findReassignCsvButton().trigger('click');

        await nextTick();

        expect(findCsvModal().findComponent(GlModal).isVisible()).toBe(true);
      });
    });

    describe('when the feature flag is disabled', () => {
      beforeEach(() => {
        createComponent({ provide: { glFeatures: { importerUserMappingReassignmentCsv: false } } });
      });

      it('does not render the button and the modal', () => {
        expect(findReassignCsvButton().exists()).toBe(false);
        expect(findCsvModal().exists()).toBe(false);
      });
    });
  });

  describe('keep all as placeholders', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('renders the button and the modal', () => {
      expect(findKeepAllAsPlaceholderButton().exists()).toBe(true);
      expect(findKeepAllAsPlaceholderModal().exists()).toBe(true);
    });

    it('shows the modal when the button is clicked', async () => {
      findKeepAllAsPlaceholderButton().trigger('click');

      await nextTick();

      expect(findKeepAllAsPlaceholderModal().findComponent(GlModal).isVisible()).toBe(true);
    });
  });

  describe('on keepAllAsPlaceholderModal "confirm" event', () => {
    beforeEach(async () => {
      const sourceUsersCount = mockSourceUsers.length;

      createComponent();
      await nextTick();

      findKeepAllAsPlaceholderModal().vm.$emit('confirm', sourceUsersCount);
      await nextTick();
    });

    it('updates tab counts', () => {
      expect(findTabAt(0).text()).toBe(
        `Awaiting reassignment ${pagination.awaitingReassignmentItems - 7}`,
      );
      expect(findTabAt(1).text()).toBe(`Reassigned ${pagination.reassignedItems + 7}`);
    });

    it('shows toast', () => {
      expect($toast.show).toHaveBeenCalledWith('7 placeholder users were kept as placeholders.');
    });
  });
});
