import { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createNewMenuGroups } from '../mock_data';

describe('CreateMenu component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlDisclosureDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);

  const createWrapper = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CreateMenu, {
      provide: {
        isImpersonating: false,
        ...provide,
      },
      propsData: {
        groups: createNewMenuGroups,
      },
      stubs: {
        InviteMembersTrigger,
        GlDisclosureDropdown,
        GlEmoji: { template: '<div/>' },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes custom offset to the dropdown', () => {
      createWrapper();

      expect(findGlDisclosureDropdown().props('dropdownOffset')).toEqual({
        crossAxis: -177,
        mainAxis: 4,
      });
    });

    it("sets the toggle's label", () => {
      expect(findGlDisclosureDropdown().props('toggleText')).toBe(__('Create new...'));
    });
    it('has correct amount of dropdown groups', () => {
      const items = findGlDisclosureDropdownGroups();

      expect(items.exists()).toBe(true);
      expect(items).toHaveLength(createNewMenuGroups.length);
    });

    it('has correct amount of dropdown items', () => {
      const items = findGlDisclosureDropdownItems();
      const numberOfMenuItems = createNewMenuGroups
        .map((group) => group.items.length)
        .reduce((a, b) => a + b);

      expect(items.exists()).toBe(true);
      expect(items).toHaveLength(numberOfMenuItems);
    });

    it('renders the invite member trigger', () => {
      expect(findInviteMembersTrigger().exists()).toBe(true);
    });

    it('hides the tooltip when the dropdown is opened', async () => {
      findGlDisclosureDropdown().vm.$emit('shown');
      await nextTick();

      const tooltip = getBinding(findGlDisclosureDropdown().element, 'gl-tooltip');
      expect(tooltip.value).toBe('');
    });

    it('shows the tooltip when the dropdown is closed', async () => {
      findGlDisclosureDropdown().vm.$emit('shown');
      findGlDisclosureDropdown().vm.$emit('hidden');
      await nextTick();

      const tooltip = getBinding(findGlDisclosureDropdown().element, 'gl-tooltip');
      expect(tooltip.value).toBe('Create new...');
    });
  });

  it('decreases the dropdown offset when impersonating a user', () => {
    createWrapper({ provide: { isImpersonating: true } });

    expect(findGlDisclosureDropdown().props('dropdownOffset')).toEqual({
      crossAxis: -143,
      mainAxis: 4,
    });
  });
});
