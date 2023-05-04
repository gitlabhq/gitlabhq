import { GlAvatarLabeled, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import * as groupsApi from '~/api/groups_api';
import * as projectsApi from '~/api/projects_api';
import GroupSelect from '~/invite_members/components/group_select.vue';

const group1 = { id: 1, full_name: 'Group One', avatar_url: 'test' };
const group2 = { id: 2, full_name: 'Group Two', avatar_url: 'test' };
const allGroups = [group1, group2];

describe('GroupSelect', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(GroupSelect, {
      propsData: {
        invalidGroups: [],
        sourceId: '1',
        isProject: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(groupsApi, 'getGroups').mockResolvedValue(allGroups);
  });

  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggle = () => findDropdown().find('button[aria-haspopup="menu"]');
  const findAvatarByLabel = (text) =>
    wrapper
      .findAllComponents(GlAvatarLabeled)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.props('label') === text);

  it('renders GlSearchBoxByType with default attributes', () => {
    createComponent();

    expect(findSearchBoxByType().exists()).toBe(true);
    expect(findSearchBoxByType().vm.$attrs).toMatchObject({
      placeholder: 'Search groups',
    });
  });

  describe('when `isProject` prop is `false`', () => {
    describe('when user types in the search input', () => {
      let resolveApiRequest;

      beforeEach(() => {
        jest.spyOn(groupsApi, 'getGroups').mockImplementation(
          () =>
            new Promise((resolve) => {
              resolveApiRequest = resolve;
            }),
        );

        createComponent();

        findSearchBoxByType().vm.$emit('input', group1.name);
      });

      it('calls the API', () => {
        resolveApiRequest(allGroups);

        expect(groupsApi.getGroups).toHaveBeenCalledWith(group1.name, {
          exclude_internal: true,
          active: true,
          order_by: 'similarity',
        });
      });

      it('displays loading icon while waiting for API call to resolve', async () => {
        expect(findSearchBoxByType().props('isLoading')).toBe(true);

        resolveApiRequest(allGroups);
        await waitForPromises();

        expect(findSearchBoxByType().props('isLoading')).toBe(false);
      });
    });
  });

  describe('when `isProject` prop is `true`', () => {
    describe('when user types in the search input', () => {
      let resolveApiRequest;

      beforeEach(() => {
        jest.spyOn(projectsApi, 'getProjectShareLocations').mockImplementation(
          () =>
            new Promise((resolve) => {
              resolveApiRequest = resolve;
            }),
        );

        createComponent({ isProject: true });

        findSearchBoxByType().vm.$emit('input', group1.name);
      });

      it('calls the API', () => {
        resolveApiRequest({ data: allGroups });

        expect(projectsApi.getProjectShareLocations).toHaveBeenCalledWith('1', {
          search: group1.name,
        });
      });

      it('displays loading icon while waiting for API call to resolve', async () => {
        expect(findSearchBoxByType().props('isLoading')).toBe(true);

        resolveApiRequest({ data: allGroups });
        await waitForPromises();

        expect(findSearchBoxByType().props('isLoading')).toBe(false);
      });
    });
  });

  describe('avatar label', () => {
    it('includes the correct attributes with name and avatar_url', async () => {
      createComponent();
      await waitForPromises();

      expect(findAvatarByLabel(group1.full_name).attributes()).toMatchObject({
        src: group1.avatar_url,
        'entity-id': `${group1.id}`,
        'entity-name': group1.full_name,
        size: '32',
      });
    });

    describe('when filtering out the group from results', () => {
      beforeEach(() => {
        createComponent({ invalidGroups: [group1.id] });
      });

      it('does not find an invalid group', () => {
        expect(findAvatarByLabel(group1.full_name)).toBe(undefined);
      });

      it('finds a group that is valid', () => {
        expect(findAvatarByLabel(group2.full_name).exists()).toBe(true);
      });
    });
  });

  describe('when group is selected from the dropdown', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();

      findAvatarByLabel(group1.full_name).trigger('click');
    });

    it('emits `input` event used by `v-model`', () => {
      expect(wrapper.emitted('input')[0][0].id).toEqual(group1.id);
    });

    it('sets dropdown toggle text to selected item', () => {
      expect(findDropdownToggle().text()).toBe(group1.full_name);
    });
  });
});
