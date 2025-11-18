import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import namespaceProjectsForLinksWidgetQuery from '~/work_items/graphql/namespace_projects_for_links_widget.query.graphql';
import { namespaceProjectsList, mockFrequentlyUsedProjects } from '../../mock_data';

Vue.use(VueApollo);

const namespaceProjectsData = namespaceProjectsList.data.namespace.projects.nodes;

describe('WorkItemProjectsListbox', () => {
  /**
   * @type {import('helpers/vue_test_utils_helper').ExtendedWrapper}
   */
  let wrapper;

  const getLocalstorageKey = () => {
    return 'root/frequent-projects';
  };

  const setLocalstorageFrequentItems = (json = mockFrequentlyUsedProjects) => {
    localStorage.setItem(getLocalstorageKey(), JSON.stringify(json));
  };

  const removeLocalstorageFrequentItems = () => {
    localStorage.removeItem(getLocalstorageKey());
  };

  const namespaceProjectsFormLinksWidgetResolver = jest
    .fn()
    .mockResolvedValue(namespaceProjectsList);

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItemFor = (fullPath) => wrapper.findByTestId(`listbox-item-${fullPath}`);
  const findRecentDropdownItems = () => findDropdown().find('ul').findAll('[role=option]');
  const findRecentDropdownItemAt = (index) => findRecentDropdownItems().at(index);
  const findAllDropdownItemsFor = (fullPath) => wrapper.findAllByTestId(`listbox-item-${fullPath}`);
  const findDropdownToggle = () => wrapper.findByTestId('base-dropdown-toggle');

  const createComponent = async ({
    isGroup = true,
    fullPath = 'group-a',
    selectedProjectFullPath = null,
    projectNamespaceFullPath = '',
  } = {}) => {
    wrapper = mountExtended(WorkItemProjectsListbox, {
      apolloProvider: createMockApollo([
        [namespaceProjectsForLinksWidgetQuery, namespaceProjectsFormLinksWidgetResolver],
      ]),
      propsData: {
        fullPath,
        isGroup,
        selectedProjectFullPath,
        projectNamespaceFullPath,
      },
    });

    await waitForPromises();
  };

  describe('group level work items', () => {
    beforeEach(async () => {
      await createComponent();
      gon.current_username = 'root';
    });

    it('renders projects in projects dropdown', () => {
      removeLocalstorageFrequentItems();

      expect(findDropdown().text()).not.toContain('Recently used');

      const dropdownItem = findDropdownItemFor(namespaceProjectsData[0].fullPath);

      expect(dropdownItem.text()).toContain(namespaceProjectsData[0].name);
      expect(dropdownItem.text()).toContain(namespaceProjectsData[0].namespace.name);
    });

    it('supports selecting a project', async () => {
      removeLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');
      await nextTick();
      await findDropdownItemFor(namespaceProjectsData[0].fullPath).trigger('click');

      expect(wrapper.emitted('selectProject').pop()).toEqual([namespaceProjectsData[0].fullPath]);
    });

    it('renders recent projects if present', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');

      await nextTick();

      expect(findDropdown().text()).toContain('Recently used');

      const content = findRecentDropdownItems();

      expect(content.exists()).toBe(true);
      expect(content).toHaveLength(mockFrequentlyUsedProjects.length);
    });

    it('supports selecting a recent project', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');
      await nextTick();
      await findRecentDropdownItemAt(0).trigger('click');

      expect(wrapper.emitted('selectProject').pop()).toEqual([namespaceProjectsData[1].fullPath]);
    });

    it('supports filtering recent projects via search input', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');

      await nextTick();

      let content = findRecentDropdownItems();

      expect(content).toHaveLength(mockFrequentlyUsedProjects.length);

      findDropdown().vm.$emit('search', 'project a');

      await waitForPromises();

      content = findRecentDropdownItems();

      expect(content).toHaveLength(1);
      expect(content.at(0).text()).toContain(namespaceProjectsData[0].name);
    });

    it('default-selects the first project from the API when there is no `selectedProjectFullPath`', async () => {
      findDropdown().vm.$emit('shown');
      await nextTick();

      expect(wrapper.emitted('selectProject')).toEqual([[namespaceProjectsData[0].fullPath]]);
    });
  });

  describe('project level work items', () => {
    beforeEach(async () => {
      await createComponent({
        isGroup: false,
        fullPath: 'group-a/example-project-a',
        selectedProjectFullPath: 'group-a/example-project-a',
      });
      gon.current_username = 'root';
    });

    it('renders projects in projects dropdown', () => {
      removeLocalstorageFrequentItems();

      expect(findDropdown().text()).not.toContain('Recently used');

      const dropdownItem = findDropdownItemFor(namespaceProjectsData[0].fullPath);

      expect(dropdownItem.text()).toContain(namespaceProjectsData[0].name);
      expect(dropdownItem.text()).toContain(namespaceProjectsData[0].namespace.name);
    });

    it('auto-selects the current project when the selected project is in the list of projects', async () => {
      await nextTick();

      expect(findDropdownToggle().text()).toBe(namespaceProjectsData[0].name);
    });

    it('auto-selects the current project for user-namespace when projectNamespaceFullPath is present', async () => {
      const projectNamespaceFullPath = 'root';
      await createComponent({
        isGroup: false,
        fullPath: 'root/example-project-a',
        projectNamespaceFullPath,
      });
      await nextTick();

      // Since `beforeEach` is already running the query once, we need to look
      // for second call with expected variables.
      expect(namespaceProjectsFormLinksWidgetResolver).toHaveBeenNthCalledWith(2, {
        fullPath: projectNamespaceFullPath,
        projectSearch: '',
      });
      expect(findDropdownToggle().text()).toBe(namespaceProjectsData[0].name);
    });

    it('auto-selects the frequently used project if the selected project is not in the list of projects', async () => {
      setLocalstorageFrequentItems();

      await createComponent({
        isGroup: false,
        selectedProjectFullPath: '/group-a/unavailable-project',
      });

      expect(findDropdownToggle().text()).toBe('Example project B');

      removeLocalstorageFrequentItems();
    });

    it('auto-selects the first project when frequently used projects are not available and the selected project is not in the list of projects', async () => {
      await createComponent({
        isGroup: false,
        selectedProjectFullPath: '/group-a/unavailable-project',
      });

      expect(findDropdownToggle().text()).toBe('Example project A');
    });

    it('supports selecting a project', async () => {
      removeLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');
      await nextTick();
      await findDropdownItemFor(namespaceProjectsData[1].fullPath).trigger('click');

      expect(wrapper.emitted('selectProject').pop()).toEqual([namespaceProjectsData[1].fullPath]);
    });

    it('renders recent projects if present', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');

      await nextTick();

      expect(findDropdown().text()).toContain('Recently used');

      const content = findRecentDropdownItems();

      expect(content.exists()).toBe(true);
      expect(content).toHaveLength(mockFrequentlyUsedProjects.length);
    });

    it('supports selecting a recent project', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');
      await nextTick();
      await findRecentDropdownItemAt(0).trigger('click');

      expect(wrapper.emitted('selectProject').pop()).toEqual([namespaceProjectsData[1].fullPath]);
    });

    it('supports filtering recent projects via search input', async () => {
      setLocalstorageFrequentItems();

      findDropdown().vm.$emit('shown');

      await nextTick();

      let content = findRecentDropdownItems();

      expect(content).toHaveLength(mockFrequentlyUsedProjects.length);

      findDropdown().vm.$emit('search', 'project a');

      await waitForPromises();

      content = findRecentDropdownItems();

      expect(content).toHaveLength(1);
      expect(content.at(0).text()).toContain(namespaceProjectsData[0].name);
    });
  });

  it('does not include duplicate projects if found in both query and localstorage results', async () => {
    await createComponent();
    gon.current_username = 'root';

    setLocalstorageFrequentItems();

    findDropdown().vm.$emit('shown');

    await nextTick();

    // de-duplicated
    expect(findAllDropdownItemsFor(namespaceProjectsData[0].fullPath)).toHaveLength(1);
    // de-duplicated
    expect(findAllDropdownItemsFor(namespaceProjectsData[1].fullPath)).toHaveLength(1);
    // only in query results
    expect(findAllDropdownItemsFor(namespaceProjectsData[2].fullPath)).toHaveLength(1);
  });
});
