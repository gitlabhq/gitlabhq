import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { GlTab, GlTabs, GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import PlaceholdersTabApp from '~/members/placeholders/components/app.vue';
import CsvUploadModal from '~/members/placeholders/components/csv_upload_modal.vue';
import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import { MEMBERS_TAB_TYPES } from '~/members/constants';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  PLACEHOLDER_STATUS_FAILED,
  QUERY_PARAM_FAILED,
  PLACEHOLDER_USER_STATUS,
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
        reassignmentCsvPath: 'foo/bar',
        group: mockGroup,
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

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabAt = (index) => wrapper.findAllComponents(GlTab).at(index);
  const findUnassignedTable = () => wrapper.findByTestId('placeholders-table-unassigned');
  const findReassignedTable = () => wrapper.findByTestId('placeholders-table-reassigned');
  const findReassignCsvButton = () => wrapper.findByTestId('reassign-csv-button');
  const findCsvModal = () => wrapper.findComponent(CsvUploadModal);

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
        'Placeholder Placeholder 2 (@placeholder_2) kept as placeholder.',
      );
    });
  });

  describe('passes the correct queryStatuses to PlaceholdersTable', () => {
    it('awaiting Reassignment - when the url includes the query param failed', () => {
      setWindowLocation(`?status=${QUERY_PARAM_FAILED}`);
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
});
