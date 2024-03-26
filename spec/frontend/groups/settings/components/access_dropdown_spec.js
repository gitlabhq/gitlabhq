import { GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { getSubGroups } from '~/groups/settings/api/access_dropdown_api';
import AccessDropdown from '~/groups/settings/components/access_dropdown.vue';

jest.mock('~/groups/settings/api/access_dropdown_api', () => ({
  getSubGroups: jest.fn().mockResolvedValue({
    data: [
      { id: 4, name: 'group4' },
      { id: 5, name: 'group5' },
      { id: 6, name: 'group6' },
    ],
  }),
}));

describe('Access Level Dropdown', () => {
  let wrapper;
  const createComponent = ({ ...optionalProps } = {}) => {
    wrapper = shallowMount(AccessDropdown, {
      propsData: {
        ...optionalProps,
      },
      stubs: {
        GlDropdown,
      },
    });
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  describe('data request', () => {
    it('should make an api call for sub-groups', () => {
      createComponent();
      expect(getSubGroups).toHaveBeenCalledWith({
        includeParentDescendants: true,
        includeParentSharedGroups: true,
        search: '',
      });
    });

    it('should not make an API call sub groups when user does not have a license', () => {
      createComponent({ hasLicense: false });
      expect(getSubGroups).not.toHaveBeenCalled();
    });

    it('should make api calls when search query is updated', async () => {
      createComponent();
      const search = 'root';

      findSearchBox().vm.$emit('input', search);
      await nextTick();
      expect(getSubGroups).toHaveBeenCalledWith({
        includeParentDescendants: true,
        includeParentSharedGroups: true,
        search,
      });
    });
  });
});
