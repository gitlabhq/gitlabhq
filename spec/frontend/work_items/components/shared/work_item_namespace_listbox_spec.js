import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemNamespaceListbox from '~/work_items/components/shared/work_item_namespace_listbox.vue';
import namespaceProjectsForLinksWidgetQuery from '~/work_items/graphql/namespace_projects_for_links_widget.query.graphql';
import namespaceGroupsForLinksWidgetQuery from '~/work_items/graphql/namespace_groups_for_links_widget.query.graphql';
import {
  namespaceProjectsList,
  mockFrequentlyUsedProjects,
  namespaceGroupsList,
} from '../../mock_data';

Vue.use(VueApollo);

const namespaceProjectsData = namespaceProjectsList.data.namespace.projects.nodes;
const namespaceGroupsData = namespaceGroupsList.data.group.descendantGroups.nodes;

const mockFrequentlyUsedGroups = [
  {
    id: 33,
    name: 'Group A',
    namespace: 'Group A',
    webUrl: '/group-a',
    avatarUrl: null,
    lastAccessedOn: 125,
    frequency: 5,
  },
];

describe('WorkItemNamespaceListbox', () => {
  let wrapper;

  const getLocalstorageKey = () => {
    return 'root/frequent-projects';
  };

  const getGroupsLocalstorageKey = () => {
    return 'root/frequent-groups';
  };

  const setLocalStorageFrequentItems = (json = mockFrequentlyUsedProjects) => {
    localStorage.setItem(getLocalstorageKey(), JSON.stringify(json));
  };

  const setLocalStorageFrequentGroups = (json = mockFrequentlyUsedGroups) => {
    localStorage.setItem(getGroupsLocalstorageKey(), JSON.stringify(json));
  };

  const removeLocalstorageFrequentItems = () => {
    localStorage.removeItem(getLocalstorageKey());
    localStorage.removeItem(getGroupsLocalstorageKey());
  };

  const namespaceProjectsFormLinksWidgetResolver = jest
    .fn()
    .mockResolvedValue(namespaceProjectsList);
  const namespaceGroupsFormLinksWidgetResolver = jest.fn().mockResolvedValue(namespaceGroupsList);

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItemFor = (fullPath) => wrapper.findByTestId(`listbox-item-${fullPath}`);
  const findRecentDropdownItems = () => findDropdown().find('ul').findAll('[role=option]');
  const findRecentDropdownItemAt = (index) => findRecentDropdownItems().at(index);
  const findAllDropdownItemsFor = (fullPath) => wrapper.findAllByTestId(`listbox-item-${fullPath}`);
  const findDropdownToggle = () => wrapper.findByTestId('base-dropdown-toggle');

  const createComponent = async ({
    isGroup = true,
    fullPath = 'group-a',
    selectedNamespacePath = null,
    projectsOnly = false,
  } = {}) => {
    wrapper = mountExtended(WorkItemNamespaceListbox, {
      apolloProvider: createMockApollo([
        [namespaceProjectsForLinksWidgetQuery, namespaceProjectsFormLinksWidgetResolver],
        [namespaceGroupsForLinksWidgetQuery, namespaceGroupsFormLinksWidgetResolver],
      ]),
      propsData: {
        fullPath,
        isGroup,
        selectedNamespacePath,
        projectsOnly,
      },
    });

    await waitForPromises();
  };

  beforeEach(async () => {
    await createComponent();
    gon.current_username = 'root';
  });

  afterEach(() => {
    removeLocalstorageFrequentItems();
  });

  it('pre-selects the current namespace', async () => {
    await nextTick();

    expect(findDropdownToggle().text()).toContain(namespaceGroupsList.data.group.name);
  });

  it('renders both projects and groups options regardless of the current namespace', () => {
    expect(findDropdown().text()).not.toContain('Recently used');

    const dropdownProjectItem = findDropdownItemFor(namespaceProjectsData[0].fullPath);
    const dropdownGroupItem = findDropdownItemFor(namespaceGroupsData[0].fullPath);

    expect(dropdownGroupItem.text()).toContain(namespaceGroupsData[0].name);
    expect(dropdownGroupItem.text()).toContain(namespaceGroupsData[0].fullName);

    expect(dropdownProjectItem.text()).toContain(namespaceProjectsData[0].name);
    expect(dropdownProjectItem.text()).toContain(namespaceProjectsData[0].nameWithNamespace);
  });

  it('supports selecting a namespace', async () => {
    findDropdown().vm.$emit('shown');
    await nextTick();

    await findDropdownItemFor(namespaceProjectsData[0].fullPath).trigger('click');
    await nextTick();

    const emitted = wrapper.emitted('select-namespace');

    expect(emitted[0][0]).toBe(namespaceProjectsData[0].fullPath);
    expect(emitted[0][1]).toEqual(
      expect.objectContaining({
        fullPath: namespaceProjectsData[0].fullPath,
        __typename: 'Project',
      }),
    );
  });

  it('renders recent projects if present', async () => {
    setLocalStorageFrequentItems();

    findDropdown().vm.$emit('shown');
    await nextTick();

    expect(findDropdown().text()).toContain('Recently used');

    expect(findRecentDropdownItems().exists()).toBe(true);
  });

  it('supports selecting a recent project', async () => {
    setLocalStorageFrequentItems();

    findDropdown().vm.$emit('shown');
    await nextTick();

    await findRecentDropdownItemAt(1).trigger('click');
    await nextTick();

    const emitted = wrapper.emitted('select-namespace');
    expect(emitted[0][0]).toBe(namespaceProjectsData[0].fullPath);
  });

  it('supports filtering via search input', async () => {
    findDropdown().vm.$emit('shown');
    await nextTick();

    findDropdown().vm.$emit('search', 'Group B');
    await waitForPromises();

    expect(findRecentDropdownItems().at(0).text()).toContain(namespaceGroupsData[0].name);
  });

  it('does not include duplicate items if found in both query and localstorage results', async () => {
    await createComponent();
    gon.current_username = 'root';

    setLocalStorageFrequentItems();

    findDropdown().vm.$emit('shown');
    await nextTick();

    // de-duplicated
    expect(findAllDropdownItemsFor(namespaceProjectsData[0].fullPath)).toHaveLength(1);
    // de-duplicated
    expect(findAllDropdownItemsFor(namespaceProjectsData[1].fullPath)).toHaveLength(1);
    // only in query results
    expect(findAllDropdownItemsFor(namespaceProjectsData[2].fullPath)).toHaveLength(1);
  });

  it('does not remove toggle text when searching', async () => {
    await createComponent();
    findDropdown().vm.$emit('shown');
    await nextTick();
    findDropdown().vm.$emit('search', 'Group B');

    // group A is the auto-selected namespace so it will still be displayed
    // in the toggle. Search results are displayed in the dropdown item list
    expect(findDropdown().props('toggleText')).toBe('Group A');
  });

  describe('when projectsOnly is true', () => {
    let groupsResolver;

    const createProjectsOnlyComponent = async () => {
      groupsResolver = jest.fn().mockResolvedValue(namespaceGroupsList);

      wrapper = mountExtended(WorkItemNamespaceListbox, {
        apolloProvider: createMockApollo([
          [namespaceProjectsForLinksWidgetQuery, namespaceProjectsFormLinksWidgetResolver],
          [namespaceGroupsForLinksWidgetQuery, groupsResolver],
        ]),
        propsData: {
          fullPath: 'group-a',
          isGroup: true,
          selectedNamespacePath: null,
          projectsOnly: true,
        },
      });

      await waitForPromises();
    };

    beforeEach(async () => {
      await createProjectsOnlyComponent();
      gon.current_username = 'root';
    });

    it('does not offer groups', () => {
      expect(findDropdownItemFor(namespaceProjectsData[0].fullPath).exists()).toBe(true);
      expect(findDropdownItemFor(namespaceGroupsData[0].fullPath).exists()).toBe(false);
    });

    it('does not request groups', () => {
      expect(groupsResolver).not.toHaveBeenCalled();
    });

    it('labels the list of options as projects', () => {
      expect(findDropdown().text()).toContain('All projects');
      expect(findDropdown().text()).not.toContain('All groups and projects');
    });

    it('does not offer recently used groups', async () => {
      setLocalStorageFrequentItems();
      setLocalStorageFrequentGroups();

      findDropdown().vm.$emit('shown');
      await nextTick();

      expect(findDropdown().text()).toContain('Recently used');
      expect(findDropdownItemFor('group-a').exists()).toBe(false);
    });

    it('asks the user to select a project when there is no namespace to default to', async () => {
      await createComponent({ fullPath: '', projectsOnly: true });

      expect(findDropdown().props('toggleText')).toBe('Select a project');
    });
  });

  it('renders without error when the group query returns null (e.g. personal namespace)', async () => {
    const nullGroupResolver = jest.fn().mockResolvedValue({ data: { group: null } });

    wrapper = mountExtended(WorkItemNamespaceListbox, {
      apolloProvider: createMockApollo([
        [namespaceProjectsForLinksWidgetQuery, namespaceProjectsFormLinksWidgetResolver],
        [namespaceGroupsForLinksWidgetQuery, nullGroupResolver],
      ]),
      propsData: {
        fullPath: 'group-a',
        isGroup: true,
        selectedNamespacePath: null,
      },
    });

    await waitForPromises();

    expect(findDropdown().exists()).toBe(true);
    expect(findDropdown().props('items')).not.toBeUndefined();
  });
});
