import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlLoadingIcon, GlSearchBoxByClick, GlSprintf } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import ImportTableRow from '~/import_entities/import_groups/components/import_table_row.vue';
import ImportTable from '~/import_entities/import_groups/components/import_table.vue';
import setTargetNamespaceMutation from '~/import_entities/import_groups/graphql/mutations/set_target_namespace.mutation.graphql';
import setNewNameMutation from '~/import_entities/import_groups/graphql/mutations/set_new_name.mutation.graphql';
import importGroupMutation from '~/import_entities/import_groups/graphql/mutations/import_group.mutation.graphql';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';

import { STATUSES } from '~/import_entities/constants';

import { availableNamespacesFixture, generateFakeEntry } from '../graphql/fixtures';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('import table', () => {
  let wrapper;
  let apolloProvider;

  const FAKE_GROUP = generateFakeEntry({ id: 1, status: STATUSES.NONE });
  const FAKE_PAGE_INFO = { page: 1, perPage: 20, total: 40, totalPages: 2 };

  const createComponent = ({ bulkImportSourceGroups }) => {
    apolloProvider = createMockApollo([], {
      Query: {
        availableNamespaces: () => availableNamespacesFixture,
        bulkImportSourceGroups,
      },
      Mutation: {
        setTargetNamespace: jest.fn(),
        setNewName: jest.fn(),
        importGroup: jest.fn(),
      },
    });

    wrapper = shallowMount(ImportTable, {
      propsData: {
        sourceUrl: 'https://demo.host',
      },
      stubs: {
        GlSprintf,
      },
      localVue,
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders loading icon while performing request', async () => {
    createComponent({
      bulkImportSourceGroups: () => new Promise(() => {}),
    });
    await waitForPromises();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('does not renders loading icon when request is completed', async () => {
    createComponent({
      bulkImportSourceGroups: () => [],
    });
    await waitForPromises();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
  });

  it('renders message about empty state when no groups are available for import', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: [],
        pageInfo: FAKE_PAGE_INFO,
      }),
    });
    await waitForPromises();

    expect(wrapper.find(GlEmptyState).props().title).toBe('No groups available for import');
  });

  it('renders import row for each group in response', async () => {
    const FAKE_GROUPS = [
      generateFakeEntry({ id: 1, status: STATUSES.NONE }),
      generateFakeEntry({ id: 2, status: STATUSES.FINISHED }),
    ];
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: FAKE_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
      }),
    });
    await waitForPromises();

    expect(wrapper.findAll(ImportTableRow)).toHaveLength(FAKE_GROUPS.length);
  });

  it('does not render status string when result list is empty', async () => {
    createComponent({
      bulkImportSourceGroups: jest.fn().mockResolvedValue({
        nodes: [],
        pageInfo: FAKE_PAGE_INFO,
      }),
    });
    await waitForPromises();

    expect(wrapper.text()).not.toContain('Showing 1-0');
  });

  describe('converts row events to mutation invocations', () => {
    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: () => ({ nodes: [FAKE_GROUP], pageInfo: FAKE_PAGE_INFO }),
      });
      return waitForPromises();
    });

    it.each`
      event                        | payload            | mutation                      | variables
      ${'update-target-namespace'} | ${'new-namespace'} | ${setTargetNamespaceMutation} | ${{ sourceGroupId: FAKE_GROUP.id, targetNamespace: 'new-namespace' }}
      ${'update-new-name'}         | ${'new-name'}      | ${setNewNameMutation}         | ${{ sourceGroupId: FAKE_GROUP.id, newName: 'new-name' }}
      ${'import-group'}            | ${undefined}       | ${importGroupMutation}        | ${{ sourceGroupId: FAKE_GROUP.id }}
    `('correctly maps $event to mutation', async ({ event, payload, mutation, variables }) => {
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      wrapper.find(ImportTableRow).vm.$emit(event, payload);
      await waitForPromises();
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation,
        variables,
      });
    });
  });

  describe('pagination', () => {
    const bulkImportSourceGroupsQueryMock = jest
      .fn()
      .mockResolvedValue({ nodes: [FAKE_GROUP], pageInfo: FAKE_PAGE_INFO });

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      return waitForPromises();
    });

    it('correctly passes pagination info from query', () => {
      expect(wrapper.find(PaginationLinks).props().pageInfo).toStrictEqual(FAKE_PAGE_INFO);
    });

    it('updates page when page change is requested', async () => {
      const REQUESTED_PAGE = 2;
      wrapper.find(PaginationLinks).props().change(REQUESTED_PAGE);

      await waitForPromises();
      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: REQUESTED_PAGE }),
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
      });
      wrapper.find(PaginationLinks).props().change(REQUESTED_PAGE);
      await waitForPromises();

      expect(wrapper.text()).toContain('Showing 21-21 of 38');
    });
  });

  describe('filters', () => {
    const bulkImportSourceGroupsQueryMock = jest
      .fn()
      .mockResolvedValue({ nodes: [FAKE_GROUP], pageInfo: FAKE_PAGE_INFO });

    beforeEach(() => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      return waitForPromises();
    });

    const findFilterInput = () => wrapper.find(GlSearchBoxByClick);

    it('properly passes filter to graphql query when search box is submitted', async () => {
      createComponent({
        bulkImportSourceGroups: bulkImportSourceGroupsQueryMock,
      });
      await waitForPromises();

      const FILTER_VALUE = 'foo';
      findFilterInput().vm.$emit('submit', FILTER_VALUE);
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
      findFilterInput().vm.$emit('submit', FILTER_VALUE);
      await waitForPromises();

      expect(wrapper.text()).toContain('Showing 1-1 of 40 groups matching filter "foo"');
    });

    it('properly resets filter in graphql query when search box is cleared', async () => {
      const FILTER_VALUE = 'foo';
      findFilterInput().vm.$emit('submit', FILTER_VALUE);
      await waitForPromises();

      bulkImportSourceGroupsQueryMock.mockClear();
      await apolloProvider.defaultClient.resetStore();
      findFilterInput().vm.$emit('clear');
      await waitForPromises();

      expect(bulkImportSourceGroupsQueryMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ filter: '' }),
        expect.anything(),
        expect.anything(),
      );
    });
  });
});
