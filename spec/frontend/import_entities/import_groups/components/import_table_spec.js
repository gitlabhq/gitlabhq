import { GlEmptyState, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createAlert } from '~/alert';
import { HTTP_STATUS_OK, HTTP_STATUS_TOO_MANY_REQUESTS } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';

import { STATUSES } from '~/import_entities/constants';
import { ROOT_NAMESPACE } from '~/import_entities/import_groups/constants';
import ImportTable from '~/import_entities/import_groups/components/import_table.vue';
import ImportStatus from '~/import_entities/import_groups/components/import_status.vue';
import ImportTargetCell from '~/import_entities/import_groups/components/import_target_cell.vue';
import ImportHistoryLink from '~/import_entities/import_groups/components//import_history_link.vue';
import importGroupsMutation from '~/import_entities/import_groups/graphql/mutations/import_groups.mutation.graphql';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import searchNamespacesWhereUserCanImportProjectsQuery from '~/import_entities/import_projects/graphql/queries/search_namespaces_where_user_can_import_projects.query.graphql';

import {
  AVAILABLE_NAMESPACES,
  availableNamespacesFixture,
  generateFakeEntry,
} from '../graphql/fixtures';

jest.mock('~/alert');
jest.mock('~/import_entities/import_groups/services/status_poller');

Vue.use(VueApollo);

describe('import table', () => {
  let wrapper;
  let apolloProvider;
  let axiosMock;

  const SOURCE_URL = 'https://demo.host';
  const FAKE_GROUP = generateFakeEntry({ id: 1, status: STATUSES.NONE });
  const FAKE_GROUPS = [
    generateFakeEntry({ id: 1, status: STATUSES.NONE }),
    generateFakeEntry({ id: 2, status: STATUSES.FINISHED }),
    generateFakeEntry({ id: 3, status: STATUSES.NONE }),
    generateFakeEntry({ id: 4, status: STATUSES.FINISHED, hasFailures: true }),
  ];

  const FAKE_PAGE_INFO = { page: 1, perPage: 20, total: 40, totalPages: 2 };
  const FAKE_VERSION_VALIDATION = {
    features: {
      projectMigration: { available: false, minVersion: '14.8.0' },
      sourceInstanceVersion: '14.6.0',
    },
  };

  const findImportSelectedDropdown = () =>
    wrapper.find('[data-testid="import-selected-groups-dropdown"]');
  const findRowImportDropdownAtIndex = (idx) =>
    wrapper.findAll('tbody td button').wrappers.filter((w) => w.text() === 'Import with projects')[
      idx
    ];
  const findPaginationDropdown = () => wrapper.findByTestId('page-size');
  const findTargetNamespaceInput = (rowWrapper) =>
    extendedWrapper(rowWrapper).findByTestId('target-namespace-input');
  const findPaginationDropdownText = () => findPaginationDropdown().find('button').text();
  const findSelectionCount = () => wrapper.find('[data-test-id="selection-count"]');
  const findNewPathCol = () => wrapper.find('[data-test-id="new-path-col"]');
  const findHistoryLink = () => wrapper.findByTestId('history-link');
  const findUnavailableFeaturesWarning = () => wrapper.findByTestId('unavailable-features-alert');
  const findImportProjectsWarning = () => wrapper.findByTestId('import-projects-warning');
  const findAllImportStatuses = () => wrapper.findAllComponents(ImportStatus);

  const findFirstImportTargetCell = () => wrapper.findAllComponents(ImportTargetCell).at(0);
  const findFirstImportTargetNamespaceText = () =>
    findFirstImportTargetCell().find('[aria-haspopup]').text();

  const triggerSelectAllCheckbox = (checked = true) =>
    wrapper.find('thead input[type=checkbox]').setChecked(checked);

  const findRowCheckbox = (idx) => wrapper.findAll('tbody td input[type=checkbox]').at(idx);
  const selectRow = (idx) => findRowCheckbox(idx).setChecked(true);

  const createComponent = ({ bulkImportSourceGroups, importGroups, defaultTargetNamespace }) => {
    apolloProvider = createMockApollo(
      [
        [
          searchNamespacesWhereUserCanImportProjectsQuery,
          () => Promise.resolve(availableNamespacesFixture),
        ],
      ],
      {
        Query: {
          bulkImportSourceGroups,
        },
        Mutation: {
          importGroups,
        },
      },
    );

    wrapper = mountExtended(ImportTable, {
      propsData: {
        groupPathRegex: /.*/,
        jobsPath: '/fake_job_path',
        sourceUrl: SOURCE_URL,
        historyPath: '/fake_history_path',
        historyShowPath: '/:id/fake_history_path',
        defaultTargetNamespace,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      apolloProvider,
    });
  };

  beforeAll(() => {
    gon.api_version = 'v4';
  });

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet(/.*\/exists$/, () => []).reply(HTTP_STATUS_OK, { exists: false });
  });

  describe('loading state', () => {
    it('renders loading icon while performing request', async () => {
      createComponent({
        bulkImportSourceGroups: () => new Promise(() => {}),
      });
      await waitForPromises();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not render loading icon when request is completed', async () => {
      createComponent({
        bulkImportSourceGroups: () => [],
      });
      await waitForPromises();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('renders message about empty state when no groups are available for import', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      expect(wrapper.findComponent(GlEmptyState).props().title).toBe('No groups found');
    });
  });

  it('renders "History" link', () => {
    createComponent({ bulkImportSourceGroups: () => [] });

    expect(findHistoryLink().attributes('href')).toBe('/fake_history_path');
  });

  it('renders import row for each group in response', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: FAKE_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
    });
    await waitForPromises();

    expect(wrapper.findAll('tbody tr')).toHaveLength(FAKE_GROUPS.length);
  });

  it('renders correct import status for each group', async () => {
    const expectedStatuses = ['Not started', 'Complete', 'Not started', 'Partially completed'];

    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: FAKE_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
    });
    await waitForPromises();

    expect(findAllImportStatuses().wrappers.map((w) => w.text())).toEqual(expectedStatuses);
  });

  it('renders import history link for imports with id', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: FAKE_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
    });
    await waitForPromises();

    const importHistoryLinks = wrapper.findAllComponents(ImportHistoryLink);

    expect(importHistoryLinks).toHaveLength(2);
    expect(importHistoryLinks.at(0).props('id')).toBe(FAKE_GROUPS[1].id);
    expect(importHistoryLinks.at(1).props('id')).toBe(FAKE_GROUPS[3].id);

    expect(importHistoryLinks.at(0).attributes('href')).toBe(
      `/${FAKE_GROUPS[1].id}/fake_history_path`,
    );
    expect(importHistoryLinks.at(1).attributes('href')).toBe(
      `/${FAKE_GROUPS[3].id}/fake_history_path`,
    );
  });

  describe('selecting import target namespace', () => {
    describe('when lastImportTarget is not defined', () => {
      beforeEach(async () => {
        createComponent({
          bulkImportSourceGroups: () => ({
            nodes: [
              {
                ...generateFakeEntry({ id: 1, status: STATUSES.NONE }),
                lastImportTarget: null,
              },
            ],
            pageInfo: FAKE_PAGE_INFO,
            versionValidation: FAKE_VERSION_VALIDATION,
          }),
        });

        await waitForPromises();
      });

      it('does not pre-select target namespace', () => {
        expect(findFirstImportTargetNamespaceText()).toBe('Select parent group');
      });

      it('does not validate by default', () => {
        expect(wrapper.find('tbody tr').text()).not.toContain('Please select a parent group.');
      });

      it('triggers validations when import button is clicked', async () => {
        await findRowImportDropdownAtIndex(0).trigger('click');

        expect(wrapper.find('tbody tr').text()).toContain('Please select a parent group.');
      });

      it('is valid when root namespace is selected', async () => {
        findFirstImportTargetCell().vm.$emit('update-target-namespace', {
          fullPath: '',
        });
        await findRowImportDropdownAtIndex(0).trigger('click');

        expect(wrapper.find('tbody tr').text()).not.toContain('Please select a parent group.');
        expect(findFirstImportTargetNamespaceText()).toBe('No parent');
      });

      it('is valid when target namespace is selected', async () => {
        findFirstImportTargetCell().vm.$emit('update-target-namespace', {
          fullPath: 'gitlab-org',
        });
        await findRowImportDropdownAtIndex(0).trigger('click');

        expect(wrapper.find('tbody tr').text()).not.toContain('Please select a parent group.');
        expect(findFirstImportTargetNamespaceText()).toBe('gitlab-org');
      });
    });

    describe('when lastImportTarget is set', () => {
      it('correctly maintains root namespace as last import target', async () => {
        createComponent({
          bulkImportSourceGroups: () => ({
            nodes: [
              {
                ...generateFakeEntry({ id: 1, status: STATUSES.NONE }),
                lastImportTarget: {
                  id: 1,
                  targetNamespace: ROOT_NAMESPACE.fullPath,
                  newName: 'does-not-matter',
                },
              },
            ],
            pageInfo: FAKE_PAGE_INFO,
            versionValidation: FAKE_VERSION_VALIDATION,
          }),
        });

        await waitForPromises();

        expect(findFirstImportTargetNamespaceText()).toBe('No parent');
      });
    });

    it('correctly maintains target namespace as last import target', async () => {
      const targetNamespace = AVAILABLE_NAMESPACES[1];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [
            {
              ...generateFakeEntry({ id: 1, status: STATUSES.FINISHED }),
              lastImportTarget: {
                id: 1,
                targetNamespace: targetNamespace.fullPath,
                newName: 'does-not-matter',
              },
            },
          ],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });

      await waitForPromises();

      expect(findFirstImportTargetNamespaceText()).toBe(targetNamespace.fullPath);
    });
  });

  it('does not render status string when result list is empty', async () => {
    createComponent({
      bulkImportSourceGroups: jest.fn().mockResolvedValue({
        nodes: [],
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
    });
    await waitForPromises();

    expect(wrapper.text()).not.toContain('Showing 1-0');
  });

  describe('when import button is clicked', () => {
    beforeEach(async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [FAKE_GROUP],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });

      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await waitForPromises();

      await findRowImportDropdownAtIndex(0).trigger('click');
    });

    it('invokes importGroups mutation', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            {
              migrateMemberships: true,
              migrateProjects: true,
              newName: FAKE_GROUP.lastImportTarget.newName,
              sourceGroupId: FAKE_GROUP.id,
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
            },
          ],
        },
      });
    });

    it('disables the import target input', () => {
      const firstRow = wrapper.find('tbody tr');
      expect(findTargetNamespaceInput(firstRow).attributes('disabled')).toBe('disabled');
    });
  });

  describe('when importGroup query is using stale data from LocalStorageCache', () => {
    it('displays error', async () => {
      const mockMutationWithProgressInvalid = jest.fn().mockResolvedValue({
        __typename: 'ClientBulkImportSourceGroup',
        id: 1,
        lastImportTarget: { id: 1, targetNamespace: 'root', newName: 'group1' },
        progress: {
          __typename: 'ClientBulkImportProgress',
          id: null,
          status: 'failed',
          message: '',
        },
      });

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [FAKE_GROUP],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
        importGroups: mockMutationWithProgressInvalid,
      });

      await waitForPromises();
      await findRowImportDropdownAtIndex(0).trigger('click');
      await waitForPromises();

      expect(mockMutationWithProgressInvalid).toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Importing the group failed.',
        captureError: true,
        error: expect.any(Error),
      });
    });
  });

  it('displays error if importing group fails', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: [FAKE_GROUP],
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
      importGroups: () => {
        throw new Error();
      },
    });

    await waitForPromises();
    await findRowImportDropdownAtIndex(0).trigger('click');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Importing the group failed.',
      captureError: true,
      error: expect.any(Error),
    });
  });

  it('displays inline error if importing group reports rate limit', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: [FAKE_GROUP],
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
      importGroups: () => {
        const error = new Error();
        error.response = { status: HTTP_STATUS_TOO_MANY_REQUESTS };
        throw error;
      },
    });

    await waitForPromises();
    await findRowImportDropdownAtIndex(0).trigger('click');
    await waitForPromises();

    expect(createAlert).not.toHaveBeenCalled();
    expect(wrapper.find('tbody tr').text()).toContain(
      'Over six imports in one minute were attempted. Wait at least one minute and try again.',
    );
  });

  it('displays inline error if backend returns validation error', async () => {
    const mockValidationError =
      'Import failed. Destination URL must not start or end with a special character and must not contain consecutive special characters.';
    const mockMutationWithProgressError = jest.fn().mockResolvedValue({
      __typename: 'ClientBulkImportSourceGroup',
      id: 1,
      lastImportTarget: { id: 1, targetNamespace: 'root', newName: 'group1' },
      progress: {
        __typename: 'ClientBulkImportProgress',
        id: null,
        status: 'failed',
        hasFailures: true,
        message: mockValidationError,
      },
    });

    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: [FAKE_GROUP],
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
      importGroups: mockMutationWithProgressError,
    });

    await waitForPromises();
    await findRowImportDropdownAtIndex(0).trigger('click');
    await waitForPromises();

    expect(mockMutationWithProgressError).toHaveBeenCalled();
    expect(createAlert).not.toHaveBeenCalled();

    const firstRow = wrapper.find('tbody tr');
    expect(findTargetNamespaceInput(firstRow).attributes('disabled')).toBeUndefined();
    expect(firstRow.text()).toContain(mockValidationError);
  });

  describe('pagination', () => {
    const bulkImportSourceGroupsQueryMock = jest.fn().mockResolvedValue({
      nodes: [FAKE_GROUP],
      pageInfo: FAKE_PAGE_INFO,
      versionValidation: FAKE_VERSION_VALIDATION,
    });

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      return waitForPromises();
    });

    it('correctly passes pagination info from query', () => {
      expect(wrapper.findComponent(PaginationLinks).props().pageInfo).toStrictEqual(FAKE_PAGE_INFO);
    });

    it('renders pagination dropdown', () => {
      expect(findPaginationDropdown().exists()).toBe(true);
    });

    it('updates page size when selected in Dropdown', async () => {
      const otherOption = findPaginationDropdown().findAll('.gl-new-dropdown-item-content').at(1);
      expect(otherOption.text()).toMatchInterpolatedText('50 items per page');

      bulkImportSourceGroupsQueryMock.mockResolvedValue({
        nodes: [FAKE_GROUP],
        pageInfo: { ...FAKE_PAGE_INFO, perPage: 50 },
        versionValidation: FAKE_VERSION_VALIDATION,
      });
      await otherOption.trigger('click');

      await waitForPromises();

      expect(findPaginationDropdownText()).toMatchInterpolatedText('50 items per page');
    });

    it('updates page when page change is requested', async () => {
      const REQUESTED_PAGE = 2;
      wrapper.findComponent(PaginationLinks).props().change(REQUESTED_PAGE);

      await waitForPromises();
      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: REQUESTED_PAGE }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('resets page to 1 when page size is changed', async () => {
      wrapper.findComponent(PaginationBar).vm.$emit('set-page', 2);
      await waitForPromises();

      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: 2, perPage: 50 }),
        expect.anything(),
        expect.anything(),
      );

      wrapper.findComponent(PaginationBar).vm.$emit('set-page-size', 200);
      await waitForPromises();

      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: 1, perPage: 200 }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('updates status text when page is changed', async () => {
      const REQUESTED_PAGE = 2;
      bulkImportSourceGroupsQueryMock.mockResolvedValue({
        nodes: [FAKE_GROUP],
        pageInfo: {
          page: 2,
          total: 38,
          perPage: 20,
          totalPages: 2,
        },
        versionValidation: FAKE_VERSION_VALIDATION,
      });
      wrapper.findComponent(PaginationLinks).props().change(REQUESTED_PAGE);
      await waitForPromises();

      expect(wrapper.text()).toContain('Showing 21-21 of 38 groups that you own from');
    });
  });

  describe('filters', () => {
    const bulkImportSourceGroupsQueryMock = jest.fn().mockResolvedValue({
      nodes: [FAKE_GROUP],
      pageInfo: FAKE_PAGE_INFO,
      versionValidation: FAKE_VERSION_VALIDATION,
    });

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      return waitForPromises();
    });

    const setFilter = (value) => {
      const input = wrapper.find('input[placeholder="Filter by source group"]');
      input.setValue(value);
      return input.trigger('keydown.enter');
    };

    it('properly passes filter to graphql query when search box is submitted', async () => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      await waitForPromises();

      const FILTER_VALUE = 'foo';
      await setFilter(FILTER_VALUE);
      await waitForPromises();

      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ filter: FILTER_VALUE }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('updates status string when search box is submitted', async () => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      await waitForPromises();

      const FILTER_VALUE = 'foo';
      await setFilter(FILTER_VALUE);
      await waitForPromises();

      expect(wrapper.text()).toContain(
        'Showing 1-1 of 40 groups that you own matching filter "foo" from',
      );
    });

    it('properly resets filter in graphql query when search box is cleared', async () => {
      const FILTER_VALUE = 'foo';
      await setFilter(FILTER_VALUE);
      await waitForPromises();

      bulkImportSourceGroupsQueryMock.mockClear();
      await apolloProvider.defaultClient.resetStore();

      await setFilter('');

      await waitForPromises();

      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ filter: '' }),
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('bulk operations', () => {
    it('import all button correctly selects/deselects all groups', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();
      expect(findSelectionCount().text()).toMatchInterpolatedText('0 selected');
      await triggerSelectAllCheckbox();
      expect(findSelectionCount().text()).toMatchInterpolatedText('2 selected');
      await triggerSelectAllCheckbox(false);
      expect(findSelectionCount().text()).toMatchInterpolatedText('0 selected');
    });

    it('import selected button is disabled when no groups selected', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      expect(findImportSelectedDropdown().props().disabled).toBe(true);
    });

    it('import selected button is enabled when groups were selected for import', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      await selectRow(0);

      expect(findImportSelectedDropdown().props().disabled).toBe(false);
    });

    it('does not render import projects warning when target with isProjectCreationAllowed = true is selected', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      await selectRow(0);
      await nextTick();

      expect(findImportProjectsWarning().exists()).toBe(false);
    });

    it('renders import projects warning when target with isProjectCreationAllowed = false is selected', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [
            {
              ...generateFakeEntry({ id: 1, status: STATUSES.NONE }),
              lastImportTarget: {
                id: 1,
                targetNamespace: AVAILABLE_NAMESPACES[2].fullPath,
                newName: 'does-not-matter',
              },
            },
          ],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      await selectRow(0);
      await nextTick();

      expect(findImportProjectsWarning().props('name')).toBe('warning');
      expect(findImportProjectsWarning().attributes('title')).toBe(
        'Some groups will be imported without projects.',
      );
    });

    it('does not allow selecting already started groups', async () => {
      const NEW_GROUPS = [generateFakeEntry({ id: 1, status: STATUSES.STARTED })];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      await selectRow(0);
      await nextTick();

      expect(findImportSelectedDropdown().props().disabled).toBe(true);
    });

    it('does not allow selecting groups with validation errors', async () => {
      const NEW_GROUPS = [
        generateFakeEntry({
          id: 2,
          status: STATUSES.NONE,
        }),
      ];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      await wrapper.find('tbody input[aria-label="New name"]').setValue('');
      jest.runOnlyPendingTimers();
      await selectRow(0);
      await nextTick();

      expect(findImportSelectedDropdown().props().disabled).toBe(true);
    });

    it('invokes importGroups mutation when import selected dropdown is clicked', async () => {
      const NEW_GROUPS = [
        generateFakeEntry({ id: 1, status: STATUSES.NONE }),
        generateFakeEntry({ id: 2, status: STATUSES.NONE }),
        generateFakeEntry({ id: 3, status: STATUSES.FINISHED }),
      ];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      await waitForPromises();

      await selectRow(0);
      await selectRow(1);
      await nextTick();

      await findImportSelectedDropdown().find('button').trigger('click');

      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[0].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[0].id,
              migrateProjects: true,
              migrateMemberships: true,
            }),
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[1].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[1].id,
              migrateProjects: true,
              migrateMemberships: true,
            }),
          ],
        },
      });
    });
  });

  it('renders pagination bar with storage key', async () => {
    createComponent({
      bulkImportSourceGroups: () => new Promise(() => {}),
    });
    await waitForPromises();

    expect(wrapper.getComponent(PaginationBar).props('storageKey')).toBe(
      ImportTable.LOCAL_STORAGE_KEY,
    );
  });

  it('displays info icon with a tooltip', async () => {
    const NEW_GROUPS = [generateFakeEntry({ id: 1, status: STATUSES.NONE })];

    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: NEW_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
        versionValidation: FAKE_VERSION_VALIDATION,
      }),
    });
    jest.spyOn(apolloProvider.defaultClient, 'mutate');
    await waitForPromises();

    const icon = findNewPathCol().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(tooltip).toBeDefined();
    expect(tooltip.value).toBe('Path of the new group.');
  });

  describe('re-import', () => {
    beforeEach(async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: [generateFakeEntry({ id: 5, status: STATUSES.FINISHED })],
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });

      await waitForPromises();
    });

    it('renders finished row as disabled by default', () => {
      expect(findRowCheckbox(0).attributes('disabled')).toBeDefined();
    });

    it('enables row after clicking re-import', async () => {
      const reimportButton = wrapper
        .findAll('tbody td button')
        .wrappers.find((w) => w.text().includes('Re-import'));

      await reimportButton.trigger('click');

      expect(findRowCheckbox(0).attributes('disabled')).toBeUndefined();
    });
  });

  describe('unavailable features warning', () => {
    it('renders alert when there are unavailable features', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      await waitForPromises();

      expect(findUnavailableFeaturesWarning().exists()).toBe(true);
      expect(findUnavailableFeaturesWarning().text()).toContain('projects (require v14.8.0)');
    });

    it('does not render alert when there are no unavailable features', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: {
            features: {
              projectMigration: { available: true, minVersion: '14.8.0' },
              sourceInstanceVersion: '14.6.0',
            },
          },
        }),
      });
      await waitForPromises();

      expect(findUnavailableFeaturesWarning().exists()).toBe(false);
    });
  });

  describe('importing projects', () => {
    const NEW_GROUPS = [
      generateFakeEntry({ id: 1, status: STATUSES.NONE }),
      generateFakeEntry({ id: 2, status: STATUSES.NONE }),
      generateFakeEntry({ id: 3, status: STATUSES.FINISHED }),
    ];

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      return waitForPromises();
    });

    it('renders import all dropdown', () => {
      expect(findImportSelectedDropdown().exists()).toBe(true);
    });

    it('includes migrateProjects: true when dropdown is clicked', async () => {
      await selectRow(0);
      await selectRow(1);
      await nextTick();
      await findImportSelectedDropdown().find('button').trigger('click');
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[0].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[0].id,
              migrateProjects: true,
              migrateMemberships: true,
            }),
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[1].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[1].id,
              migrateProjects: true,
              migrateMemberships: true,
            }),
          ],
        },
      });
    });

    it('includes migrateProjects: false when dropdown item is clicked', async () => {
      await selectRow(0);
      await selectRow(1);
      await nextTick();
      await findImportSelectedDropdown().find('.gl-dropdown-item button').trigger('click');
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[0].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[0].id,
              migrateProjects: false,
              migrateMemberships: true,
            }),
            expect.objectContaining({
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
              newName: NEW_GROUPS[1].lastImportTarget.newName,
              sourceGroupId: NEW_GROUPS[1].id,
              migrateProjects: false,
              migrateMemberships: true,
            }),
          ],
        },
      });
    });
  });

  describe('migrateMemberships', () => {
    const findImportUserMembershipsCheckbox = () =>
      wrapper.find('[data-testid="toggle-import-user-memberships"]');

    it('checkbox is rendered as checked by default', async () => {
      await createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });

      await waitForPromises();
      expect(findImportUserMembershipsCheckbox().element.checked).toBe(true);
    });

    it('is included as false in the importGroupsMutation when checkbox is unchecked', async () => {
      await createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
          versionValidation: FAKE_VERSION_VALIDATION,
        }),
      });
      const mutateSpy = jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await waitForPromises();
      await findImportUserMembershipsCheckbox().setChecked(false);
      await nextTick();

      await findRowImportDropdownAtIndex(0).trigger('click');
      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: {
          importRequests: [
            {
              migrateMemberships: false,
              migrateProjects: true,
              newName: FAKE_GROUP.lastImportTarget.newName,
              sourceGroupId: FAKE_GROUP.id,
              targetNamespace: AVAILABLE_NAMESPACES[0].fullPath,
            },
          ],
        },
      });
    });
  });
});
