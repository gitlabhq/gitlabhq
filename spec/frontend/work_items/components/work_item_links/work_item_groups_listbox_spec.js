import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import WorkItemGroupsListbox from '~/work_items/components/work_item_links/work_item_groups_listbox.vue';
import namespaceGroupsForLinksWidgetQuery from '~/work_items/graphql/namespace_groups_for_links_widget.query.graphql';
import { namespaceGroupsList } from '../../mock_data';

Vue.use(VueApollo);

const namespaceGroupsData = namespaceGroupsList.data.group.descendantGroups.nodes;

describe('WorkItemGroupsListbox', () => {
  /**
   * @type {import('helpers/vue_test_utils_helper').ExtendedWrapper}
   */
  let wrapper;

  const namespaceGroupsFormLinksWidgetResolver = jest.fn().mockResolvedValue(namespaceGroupsList);

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItemFor = (fullPath) => wrapper.findByTestId(`listbox-item-${fullPath}`);

  const createComponent = async ({
    isGroup = true,
    fullPath = 'group-a',
    selectedGroupFullPath = null,
    queryResolver = namespaceGroupsFormLinksWidgetResolver,
  } = {}) => {
    wrapper = mountExtended(WorkItemGroupsListbox, {
      apolloProvider: createMockApollo([[namespaceGroupsForLinksWidgetQuery, queryResolver]]),
      propsData: {
        fullPath,
        isGroup,
        selectedGroupFullPath,
      },
    });

    await waitForPromises();
  };

  beforeEach(() => {
    gon.current_username = 'root';
  });

  it('renders group avatar', async () => {
    await createComponent();

    expect(wrapper.findComponent(ProjectAvatar).props()).toMatchObject({
      projectAvatarUrl: 'http://example.com/avatar-url',
      projectId: 'gid://gitlab/Group/33',
      projectName: 'Group A',
    });
  });

  it('renders groups in groups dropdown', async () => {
    await createComponent();
    const dropdownItem = findDropdownItemFor(namespaceGroupsData[0].fullPath);

    expect(dropdownItem.text()).toContain(namespaceGroupsData[0].name);
    expect(dropdownItem.text()).toContain(namespaceGroupsData[0].path);
  });

  it('supports selecting a group', async () => {
    await createComponent();
    findDropdown().vm.$emit('shown');
    await nextTick();

    await findDropdownItemFor(namespaceGroupsData[0].fullPath).trigger('click');

    expect(wrapper.emitted('selectGroup')).toEqual([[namespaceGroupsData[0].fullPath]]);
  });

  describe('with a default group', () => {
    it('auto-selects the current group', async () => {
      await createComponent({ selectedGroupFullPath: 'group-a' });

      expect(findDropdown().props('toggleText')).toBe('Group A');
    });
  });

  describe('without a default group', () => {
    it('shows "Select a group"', async () => {
      await createComponent();

      expect(findDropdown().props('toggleText')).toBe('Select a group');
    });
  });

  describe('search', () => {
    it('renders group with no search', async () => {
      await createComponent();

      expect(findDropdownItemFor('group-a').exists()).toBe(true);
    });

    it('includes group when it matches search', async () => {
      await createComponent();
      findDropdown().vm.$emit('search', 'Group A');
      await waitForPromises();

      expect(findDropdownItemFor('group-a').exists()).toBe(true);
    });

    it('excludes group when it does not match search', async () => {
      await createComponent();
      findDropdown().vm.$emit('search', 'Group B');
      await waitForPromises();

      expect(findDropdownItemFor('group-a').exists()).toBe(false);
    });

    it('calls query when making a search', async () => {
      await createComponent();

      expect(namespaceGroupsFormLinksWidgetResolver).toHaveBeenCalledWith({
        fullPath: 'group-a',
        groupSearch: '',
      });

      findDropdown().vm.$emit('search', 'Group B');
      await waitForPromises();

      expect(namespaceGroupsFormLinksWidgetResolver).toHaveBeenLastCalledWith({
        fullPath: 'group-a',
        groupSearch: 'Group B',
      });
    });

    it('emits an error when query has an error', async () => {
      await createComponent({ queryResolver: jest.fn().mockRejectedValue(new Error('whoops!')) });

      expect(wrapper.emitted('error')).toEqual([['There was a problem fetching groups.']]);
    });
  });
});
