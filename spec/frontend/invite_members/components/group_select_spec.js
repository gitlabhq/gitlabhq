import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import GroupSelect from '~/invite_members/components/group_select.vue';

const createComponent = () => {
  return mount(GroupSelect, {});
};

const group1 = { id: 1, full_name: 'Group One' };
const group2 = { id: 2, full_name: 'Group Two' };
const allGroups = [group1, group2];

describe('GroupSelect', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(Api, 'groups').mockResolvedValue(allGroups);

    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggle = () => findDropdown().find('button[aria-haspopup="true"]');
  const findDropdownItemByText = (text) =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.text() === text);

  it('renders GlSearchBoxByType with default attributes', () => {
    expect(findSearchBoxByType().exists()).toBe(true);
    expect(findSearchBoxByType().vm.$attrs).toMatchObject({
      placeholder: 'Search groups',
    });
  });

  describe('when user types in the search input', () => {
    let resolveApiRequest;

    beforeEach(() => {
      jest.spyOn(Api, 'groups').mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveApiRequest = resolve;
          }),
      );

      findSearchBoxByType().vm.$emit('input', group1.name);
    });

    it('calls the API', () => {
      resolveApiRequest({ data: allGroups });

      expect(Api.groups).toHaveBeenCalledWith(group1.name, {
        active: true,
        exclude_internal: true,
      });
    });

    it('displays loading icon while waiting for API call to resolve', async () => {
      expect(findSearchBoxByType().props('isLoading')).toBe(true);

      resolveApiRequest({ data: allGroups });
      await waitForPromises();

      expect(findSearchBoxByType().props('isLoading')).toBe(false);
    });
  });

  describe('when group is selected from the dropdown', () => {
    beforeEach(() => {
      findDropdownItemByText(group1.full_name).vm.$emit('click');
    });

    it('emits `input` event used by `v-model`', () => {
      expect(wrapper.emitted('input')[0][0].id).toEqual(group1.id);
    });

    it('sets dropdown toggle text to selected item', () => {
      expect(findDropdownToggle().text()).toBe(group1.full_name);
    });
  });
});
