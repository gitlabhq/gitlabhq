import { GlDisclosureDropdown, GlTooltip } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import { createNewMenuGroups } from '../mock_data';

describe('CreateMenu component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);

  const createWrapper = () => {
    wrapper = shallowMountExtended(CreateMenu, {
      propsData: {
        groups: createNewMenuGroups,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it("sets the toggle's label", () => {
      expect(findGlDisclosureDropdown().props('toggleText')).toBe(__('Create new...'));
    });

    it('passes the groups to the disclosure dropdown', () => {
      expect(findGlDisclosureDropdown().props('items')).toBe(createNewMenuGroups);
    });

    it("sets the toggle ID and tooltip's target", () => {
      expect(findGlDisclosureDropdown().props('toggleId')).toBe(wrapper.vm.$options.toggleId);
      expect(findGlTooltip().props('target')).toBe(`#${wrapper.vm.$options.toggleId}`);
    });
  });
});
