import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlDisclosureDropdown, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTypesList from '~/work_items/components/work_item_types_list.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import { namespaceWorkItemTypesQueryResponse } from 'ee_else_ce_jest/work_items/mock_data';

Vue.use(VueApollo);

describe('WorkItemTypesList', () => {
  let wrapper;
  let mockApollo;

  const mockEmptyResponse = {
    data: {
      workspace: {
        workItemTypes: {
          nodes: [],
          __typename: 'WorkItemTypeConnection',
        },
        __typename: 'Namespace',
      },
    },
  };

  const getMockWorkItemTypes = () =>
    namespaceWorkItemTypesQueryResponse.data.workspace.workItemTypes.nodes;
  const mockWorkItemTypes = getMockWorkItemTypes();
  const namespaceQueryHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const mockEmptyResponseHandler = jest.fn().mockResolvedValue(mockEmptyResponse);

  const createWrapper = ({ queryHandler = namespaceQueryHandler, props = {} } = {}) => {
    mockApollo = createMockApollo([[namespaceWorkItemTypesQuery, queryHandler]]);

    wrapper = shallowMountExtended(WorkItemTypesList, {
      apolloProvider: mockApollo,
      propsData: {
        fullPath: 'test-group',
        ...props,
      },
      stubs: {
        CrudComponent,
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemTypesTable = () => wrapper.findByTestId('work-item-types-table');
  const findWorkItemTypeRows = () => wrapper.findAll('[data-testid^="work-item-type-row"]');
  const findWorkItemTypeRow = (id) => wrapper.findByTestId(`work-item-type-row-${id}`);
  const findNewTypeButton = () => wrapper.findComponent(GlButton);
  const findDropdownForType = (id) => findWorkItemTypeRow(id).findComponent(GlDisclosureDropdown);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  describe('default rendering', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('renders the component with CrudComponent', () => {
      expect(findCrudComponent().exists()).toBe(true);
    });

    it('renders with correct title and count', () => {
      expect(findCrudComponent().props('title')).toBe('Types');
      expect(findCrudComponent().props('count')).toBe(mockWorkItemTypes.length);
    });

    it('renders the work item types table', () => {
      expect(findWorkItemTypesTable().exists()).toBe(true);
    });

    it('renders WorkItemTypeIcon for each type', () => {
      const icons = wrapper.findAllComponents(WorkItemTypeIcon);

      expect(icons).toHaveLength(mockWorkItemTypes.length);
      icons.wrappers.forEach((icon, index) => {
        expect(icon.props()).toMatchObject({
          workItemType: mockWorkItemTypes[index].name,
        });
      });
    });

    it('renders New type button', () => {
      expect(findNewTypeButton().exists()).toBe(true);
      expect(findNewTypeButton().text()).toContain('New type');
    });

    it('renders dropdown for each work item type', () => {
      const dropdowns = wrapper.findAllComponents(GlDisclosureDropdown);

      expect(dropdowns).toHaveLength(mockWorkItemTypes.length);
    });

    it('renders dropdowns with correct items', () => {
      mockWorkItemTypes.forEach((mockWorkItemType) => {
        const dropdown = findDropdownForType(mockWorkItemType.id);
        expect(dropdown.props('items')).toHaveLength(2);
        expect(dropdown.props('items')[0].text).toContain('Edit name and icon');
        expect(dropdown.props('items')[1].text).toContain('Delete');
      });
    });

    it('renders dropdown with correct toggle attributes', () => {
      const dropdown = findDropdownForType(mockWorkItemTypes[0].id);

      expect(dropdown.props('toggleId')).toBe(`work-item-type-actions-${mockWorkItemTypes[0].id}`);
      expect(dropdown.props('icon')).toBe('ellipsis_v');
      expect(dropdown.props('noCaret')).toBe(true);
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows loading state when query is loading', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findWorkItemTypesTable().exists()).toBe(false);
    });

    it('hides loading state after query resolves', async () => {
      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findWorkItemTypesTable().exists()).toBe(true);
    });
  });

  describe('empty state', () => {
    beforeEach(async () => {
      createWrapper({ queryHandler: mockEmptyResponseHandler });
      await waitForPromises();
    });

    it('renders table even when no work item types exist', () => {
      expect(findWorkItemTypesTable().exists()).toBe(true);
    });

    it('displays zero count', () => {
      expect(findCrudComponent().props('count')).toBe(0);
    });

    it('does not render any work item type rows', () => {
      expect(findWorkItemTypeRows()).toHaveLength(0);
    });

    it('still renders New type button', () => {
      expect(findNewTypeButton().exists()).toBe(true);
    });
  });

  describe('query behavior', () => {
    it('passes correct fullPath to query', async () => {
      createWrapper({ props: { fullPath: 'my-group/sub-group' } });

      await waitForPromises();

      expect(namespaceQueryHandler).toHaveBeenCalledWith({
        fullPath: 'my-group/sub-group',
        onlyAvailable: false,
      });
    });

    it('error handling', async () => {
      const errorQueryHandler = jest.fn().mockRejectedValue('Network error');
      createWrapper({ queryHandler: errorQueryHandler });

      await waitForPromises();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Failed to fetch work item types');
    });
  });
});
