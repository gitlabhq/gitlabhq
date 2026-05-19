import { GlButton, GlTruncate, GlCollapsibleListbox, GlListboxItem, GlAvatar } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'helpers/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import GroupsDropdownFilter from '~/analytics/shared/components/groups_dropdown_filter.vue';
import GetGroupsQuery from '~/analytics/shared/graphql/groups.query.graphql';

Vue.use(VueApollo);

const mockGroups = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'Gitlab Org',
    fullPath: 'gitlab-org',
    avatarUrl: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 'gid://gitlab/Group/2',
    name: 'Gitlab Com',
    fullPath: 'gitlab-com',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Group/3',
    name: 'Foo',
    fullPath: 'gitlab-foo',
    avatarUrl: null,
  },
];

describe('GroupsDropdownFilter component', () => {
  let wrapper;
  let mockHandler;

  const createComponent = async ({
    mountFn = shallowMountExtended,
    props = {},
    stubs = {},
  } = {}) => {
    mockHandler = jest.fn().mockResolvedValue({
      data: { groups: { nodes: mockGroups } },
    });

    const apolloProvider = createMockApollo([[GetGroupsQuery, mockHandler]]);

    wrapper = mountFn(GroupsDropdownFilter, {
      apolloProvider,
      propsData: {
        ...props,
      },
      stubs: {
        GlButton,
        GlCollapsibleListbox,
        ...stubs,
      },
    });

    await waitForPromises();
  };

  const findSelectedGroupsLabel = () => wrapper.findComponent(GlTruncate);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItems = () => findDropdown().findAllComponents(GlListboxItem);
  const findDropdownAtIndex = (index) => findDropdownItems().at(index);
  const findDropdownButton = () => findDropdown().findComponent(GlButton);
  const findDropdownButtonAvatar = () => findDropdown().find('.gl-avatar');
  const findDropdownButtonAvatarAtIndex = (index) =>
    findDropdownAtIndex(index).findComponent(GlAvatar);
  const findDropdownButtonIdentIconAtIndex = (index) =>
    findDropdownAtIndex(index).find('div.gl-avatar-identicon');
  const findDropdownNameAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="group-name"]');
  const findDropdownFullPathAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="group-full-path"]');

  const selectDropdownItemAtIndex = async (indexes, multi = true) => {
    const payload = indexes.map((index) => mockGroups[index]?.id).filter(Boolean);

    findDropdown().vm.$emit('select', multi ? payload : payload[0]);
    await nextTick();
  };

  const findSelectedDropdownItems = () =>
    findDropdownItems().filter((component) => component.props('isSelected') === true);

  describe('when fetching data', () => {
    const mockQueryParams = {
      first: 50,
      topLevelOnly: false,
    };

    beforeEach(async () => {
      await createComponent({
        props: {
          queryParams: mockQueryParams,
        },
      });
    });

    it('should apply the correct queryParams when making an API call', async () => {
      findDropdown().vm.$emit('search', 'gitlab');

      await waitForPromises();

      expect(mockHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          search: 'gitlab',
          ...mockQueryParams,
        }),
      );
    });

    it('should not make an API call when search query is below minimum search length', async () => {
      mockHandler.mockClear();

      findDropdown().vm.$emit('search', 'hi');

      await waitForPromises();

      expect(mockHandler).toHaveBeenCalledTimes(0);
    });
  });

  describe('highlighted items', () => {
    const blockDefaultProps = { multiSelect: true };

    beforeEach(() => {
      return createComponent({ props: blockDefaultProps });
    });

    describe('with no group selected', () => {
      it('does not render the highlighted items', () => {
        expect(findSelectedDropdownItems()).toHaveLength(0);
      });

      it('renders the default group label text', async () => {
        await createComponent({ mountFn: mountExtended, props: blockDefaultProps });

        expect(findSelectedGroupsLabel().text()).toBe('Select a group');
      });
    });

    describe('with a selected group', () => {
      beforeEach(() => {
        return createComponent({ mountFn: mountExtended, props: blockDefaultProps });
      });

      it('renders the highlighted items', async () => {
        await selectDropdownItemAtIndex([0], false);

        expect(findSelectedDropdownItems()).toHaveLength(1);
      });

      it('renders the highlighted items title', async () => {
        await selectDropdownItemAtIndex([0], false);

        expect(findSelectedGroupsLabel().text()).toBe(mockGroups[0].name);
      });

      it('clears all selected items when the clear all button is clicked', async () => {
        await selectDropdownItemAtIndex([0, 1]);

        expect(findSelectedGroupsLabel().text()).toBe('2 groups selected');

        await findDropdown().vm.$emit('reset');

        expect(findSelectedGroupsLabel().text()).toBe('Select a group');
        expect(wrapper.emitted('selected')).toEqual([[[]]]);
      });
    });
  });

  describe.each([true, false])('when loadingDefaultGroups = %s', (loadingDefaultGroups) => {
    beforeEach(() => {
      return createComponent({
        mountFn: mountExtended,
        props: { loadingDefaultGroups },
      });
    });

    it('sets the button loading state', () => {
      expect(findDropdownButton().props('loading')).toBe(loadingDefaultGroups);
    });
  });

  describe('when passed an array of defaultGroups as prop', () => {
    beforeEach(() => {
      return createComponent({
        mountFn: mountExtended,
        props: {
          defaultGroups: [mockGroups[0]],
        },
      });
    });

    it("displays the defaultGroup's name", () => {
      expect(findDropdownButton().text()).toContain(mockGroups[0].name);
    });

    it("renders the defaultGroup's avatar", () => {
      expect(findDropdownButtonAvatar().exists()).toBe(true);
    });

    it('marks the defaultGroup as selected', () => {
      expect(
        wrapper.findAll('[role="group"]').at(0).findAllComponents(GlListboxItem).at(0).text(),
      ).toContain(mockGroups[0].name);
    });
  });

  describe('when multiSelect is true', () => {
    beforeEach(async () => {
      await createComponent({ props: { multiSelect: true } });
    });

    describe('displays the correct information', () => {
      it('contains 3 items', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders an avatar when the group has an avatarUrl', () => {
        expect(findDropdownButtonAvatarAtIndex(0).props('src')).toBe(mockGroups[0].avatarUrl);
        expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("does not render an avatar when the group doesn't have an avatarUrl", () => {
        expect(findDropdownButtonAvatarAtIndex(1).props('src')).toEqual(null);
      });

      it('renders the group name', () => {
        mockGroups.forEach((group, index) => {
          expect(findDropdownNameAtIndex(index).text()).toBe(group.name);
        });
      });

      it('renders the group fullPath', () => {
        mockGroups.forEach((group, index) => {
          expect(findDropdownFullPathAtIndex(index).text()).toBe(group.fullPath);
        });
      });
    });

    describe('on group click', () => {
      it('should add to selection when new group is clicked', async () => {
        await selectDropdownItemAtIndex([0, 1]);

        expect(findSelectedDropdownItems().at(0).text()).toContain(mockGroups[1].name);
        expect(findSelectedDropdownItems().at(1).text()).toContain(mockGroups[0].name);
      });

      it('should remove from selection when clicked again', async () => {
        await selectDropdownItemAtIndex([0]);

        expect(findSelectedDropdownItems().at(0).text()).toContain(mockGroups[0].name);

        await selectDropdownItemAtIndex([]);

        expect(findSelectedDropdownItems()).toHaveLength(0);
      });

      it('renders the correct placeholder text when multiple groups are selected', async () => {
        await createComponent({ props: { multiSelect: true }, mountFn: mountExtended });

        await selectDropdownItemAtIndex([0, 1]);

        expect(findDropdownButton().text()).toBe('2 groups selected');
      });
    });

    describe('with a selected group and search term', () => {
      beforeEach(async () => {
        await createComponent({ props: { multiSelect: true } });

        await selectDropdownItemAtIndex([0]);

        findDropdown().vm.$emit('search', 'this is a very long search string');

        await nextTick();
      });

      it('renders the highlighted items', () => {
        expect(findSelectedDropdownItems()).toHaveLength(1);
      });

      it('hides the unhighlighted items that do not match the string', () => {
        expect(wrapper.find(`[name="Selected"]`).findAllComponents(GlListboxItem)).toHaveLength(1);
        expect(wrapper.find(`[name="Unselected"]`).findAllComponents(GlListboxItem)).toHaveLength(
          0,
        );
      });
    });

    describe('with an array of groups passed to `defaultGroups` and a search term', () => {
      const { name: searchQuery } = mockGroups[2];

      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
          props: {
            multiSelect: true,
            defaultGroups: [mockGroups[0], mockGroups[1]],
          },
        });

        findDropdown().vm.$emit('search', searchQuery);
      });

      it('should add search result to selected groups when selected', async () => {
        await selectDropdownItemAtIndex([0, 1, 2]);

        expect(findSelectedDropdownItems()).toHaveLength(3);
        expect(findDropdownButton().text()).toBe('3 groups selected');
      });
    });
  });
});
