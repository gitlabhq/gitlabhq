import {
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlSearchBoxByClick,
  GlDropdown,
  GlDropdownItem,
  GlTable,
} from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import stubChildren from 'helpers/stub_children';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { STATUSES } from '~/import_entities/constants';
import ImportTable from '~/import_entities/import_groups/components/import_table.vue';
import ImportTargetCell from '~/import_entities/import_groups/components/import_target_cell.vue';
import importGroupsMutation from '~/import_entities/import_groups/graphql/mutations/import_groups.mutation.graphql';
import setImportTargetMutation from '~/import_entities/import_groups/graphql/mutations/set_import_target.mutation.graphql';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';

import { availableNamespacesFixture, generateFakeEntry } from '../graphql/fixtures';

const localVue = createLocalVue();
localVue.use(VueApollo);

const GlDropdownStub = stubComponent(GlDropdown, {
  template: '<div><h1 ref="text"><slot name="button-content"></slot></h1><slot></slot></div>',
});

describe('import table', () => {
  let wrapper;
  let apolloProvider;

  const SOURCE_URL = 'https://demo.host';
  const FAKE_GROUP = generateFakeEntry({ id: 1, status: STATUSES.NONE });
  const FAKE_GROUPS = [
    generateFakeEntry({ id: 1, status: STATUSES.NONE }),
    generateFakeEntry({ id: 2, status: STATUSES.FINISHED }),
  ];
  const FAKE_PAGE_INFO = { page: 1, perPage: 20, total: 40, totalPages: 2 };

  const findImportSelectedButton = () =>
    wrapper.findAllComponents(GlButton).wrappers.find((w) => w.text() === 'Import selected');
  const findPaginationDropdown = () => wrapper.findComponent(GlDropdown);
  const findPaginationDropdownText = () => findPaginationDropdown().find({ ref: 'text' }).text();

  // TODO: remove this ugly approach when
  // issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1531
  const findTable = () => wrapper.vm.getTableRef();

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

    wrapper = mount(ImportTable, {
      propsData: {
        groupPathRegex: /.*/,
        sourceUrl: SOURCE_URL,
        groupUrlErrorMessage: 'Please choose a group URL with no special characters or spaces.',
      },
      stubs: {
        ...stubChildren(ImportTable),
        GlSprintf: false,
        GlDropdown: GlDropdownStub,
        GlTable: false,
      },
      localVue,
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
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

    expect(wrapper.find(GlEmptyState).props().title).toBe('You have no groups to import');
  });

  it('renders import row for each group in response', async () => {
    createComponent({
      bulkImportSourceGroups: () => ({
        nodes: FAKE_GROUPS,
        pageInfo: FAKE_PAGE_INFO,
      }),
    });
    await waitForPromises();

    expect(wrapper.findAll('tbody tr')).toHaveLength(FAKE_GROUPS.length);
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
      event                        | payload            | mutation                   | variables
      ${'update-target-namespace'} | ${'new-namespace'} | ${setImportTargetMutation} | ${{ sourceGroupId: FAKE_GROUP.id, targetNamespace: 'new-namespace', newName: 'group1' }}
      ${'update-new-name'}         | ${'new-name'}      | ${setImportTargetMutation} | ${{ sourceGroupId: FAKE_GROUP.id, targetNamespace: 'root', newName: 'new-name' }}
    `('correctly maps $event to mutation', async ({ event, payload, mutation, variables }) => {
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      wrapper.find(ImportTargetCell).vm.$emit(event, payload);
      await waitForPromises();
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation,
        variables,
      });
    });

    it('invokes importGroups mutation when row button is clicked', async () => {
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      const triggerImportButton = wrapper
        .findAllComponents(GlButton)
        .wrappers.find((w) => w.text() === 'Import');

      triggerImportButton.vm.$emit('click');
      await waitForPromises();
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: { sourceGroupIds: [FAKE_GROUP.id] },
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

    it('renders pagination dropdown', () => {
      expect(findPaginationDropdown().exists()).toBe(true);
    });

    it('updates page size when selected in Dropdown', async () => {
      const otherOption = wrapper.findAllComponents(GlDropdownItem).at(1);
      expect(otherOption.text()).toMatchInterpolatedText('50 items per page');

      otherOption.vm.$emit('click');
      await waitForPromises();

      expect(findPaginationDropdownText()).toMatchInterpolatedText('50 items per page');
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

      expect(wrapper.text()).toContain('Showing 21-21 of 38 groups from');
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

      expect(wrapper.text()).toContain('Showing 1-1 of 40 groups matching filter "foo" from');
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

  describe('bulk operations', () => {
    it('import selected button is disabled when no groups selected', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
        }),
      });
      await waitForPromises();

      expect(findImportSelectedButton().props().disabled).toBe(true);
    });

    it('import selected button is enabled when groups were selected for import', async () => {
      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: FAKE_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
        }),
      });
      await waitForPromises();
      wrapper.find(GlTable).vm.$emit('row-selected', [FAKE_GROUPS[0]]);
      await nextTick();

      expect(findImportSelectedButton().props().disabled).toBe(false);
    });

    it('does not allow selecting already started groups', async () => {
      const NEW_GROUPS = [generateFakeEntry({ id: 1, status: STATUSES.FINISHED })];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
        }),
      });
      await waitForPromises();

      findTable().selectRow(0);
      await nextTick();

      expect(findImportSelectedButton().props().disabled).toBe(true);
    });

    it('does not allow selecting groups with validation errors', async () => {
      const NEW_GROUPS = [
        generateFakeEntry({
          id: 2,
          status: STATUSES.NONE,
          validation_errors: [{ field: 'new_name', message: 'FAKE_VALIDATION_ERROR' }],
        }),
      ];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
        }),
      });
      await waitForPromises();

      // TODO: remove this ugly approach when
      // issue: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1531
      findTable().selectRow(0);
      await nextTick();

      expect(findImportSelectedButton().props().disabled).toBe(true);
    });

    it('invokes importGroups mutation when import selected button is clicked', async () => {
      const NEW_GROUPS = [
        generateFakeEntry({ id: 1, status: STATUSES.NONE }),
        generateFakeEntry({ id: 2, status: STATUSES.NONE }),
        generateFakeEntry({ id: 3, status: STATUSES.FINISHED }),
      ];

      createComponent({
        bulkImportSourceGroups: () => ({
          nodes: NEW_GROUPS,
          pageInfo: FAKE_PAGE_INFO,
        }),
      });
      jest.spyOn(apolloProvider.defaultClient, 'mutate');
      await waitForPromises();

      findTable().selectRow(0);
      findTable().selectRow(1);
      await nextTick();

      findImportSelectedButton().vm.$emit('click');

      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: importGroupsMutation,
        variables: { sourceGroupIds: [NEW_GROUPS[0].id, NEW_GROUPS[1].id] },
      });
    });
  });
});
