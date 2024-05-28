import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemProjectsListbox from '~/work_items/components/work_item_links/work_item_projects_listbox.vue';
import groupProjectsForLinksWidgetQuery from '~/work_items/graphql/group_projects_for_links_widget.query.graphql';
import { SEARCH_DEBOUNCE } from '~/work_items/constants';
import { groupProjectsList, mockFrequentlyUsedProjects } from '../../mock_data';

Vue.use(VueApollo);

const projectData = groupProjectsList.data.group.projects.nodes;

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

  const groupProjectsFormLinksWidgetResolver = jest.fn().mockResolvedValue(groupProjectsList);

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItemFor = (fullPath) => wrapper.findByTestId(`listbox-item-${fullPath}`);
  const findRecentDropdownItems = () => findDropdown().find('ul').findAll('[role=option]');
  const findRecentDropdownItemAt = (index) => findRecentDropdownItems().at(index);

  const createComponent = async () => {
    wrapper = mountExtended(WorkItemProjectsListbox, {
      apolloProvider: createMockApollo([
        [groupProjectsForLinksWidgetQuery, groupProjectsFormLinksWidgetResolver],
      ]),
      propsData: {
        fullPath: 'group-a',
        isGroup: true,
      },
    });

    jest.advanceTimersByTime(SEARCH_DEBOUNCE);
    await waitForPromises();
  };

  beforeEach(async () => {
    await createComponent();
    gon.current_username = 'root';
  });

  it('renders projects in projects dropdown', () => {
    removeLocalstorageFrequentItems();

    expect(findDropdown().text()).not.toContain('Recently used');

    const dropdownItem = findDropdownItemFor(projectData[0].fullPath);

    expect(dropdownItem.text()).toContain(projectData[0].name);
    expect(dropdownItem.text()).toContain(projectData[0].namespace.name);
  });

  it('supports selecting a project', async () => {
    removeLocalstorageFrequentItems();

    findDropdown().vm.$emit('shown');

    await nextTick();

    await findDropdownItemFor(projectData[0].fullPath).trigger('click');

    await nextTick();

    const emitted = wrapper.emitted('selectProject');

    expect(emitted[0][0]).toEqual(projectData[0]);
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

    await nextTick();

    const emitted = wrapper.emitted('selectProject');

    expect(emitted[0][0]).toEqual(projectData[1]);
  });

  it('supports filtering recent projects via search input', async () => {
    setLocalstorageFrequentItems();

    findDropdown().vm.$emit('shown');

    await nextTick();

    let content = findRecentDropdownItems();

    expect(content).toHaveLength(mockFrequentlyUsedProjects.length);

    findDropdown().vm.$emit('search', 'project a');

    await nextTick();

    content = findRecentDropdownItems();

    expect(content).toHaveLength(1);
    expect(content.at(0).text()).toContain(projectData[0].name);
  });
});
