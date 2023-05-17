import { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlTooltip,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import { createNewMenuGroups } from '../mock_data';

describe('CreateMenu component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlDisclosureDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);

  const closeAndFocusMock = jest.fn();

  const createWrapper = () => {
    wrapper = shallowMountExtended(CreateMenu, {
      propsData: {
        groups: createNewMenuGroups,
      },
      stubs: {
        InviteMembersTrigger,
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          methods: { closeAndFocus: closeAndFocusMock },
        }),
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes popper options to the dropdown', () => {
      createWrapper();

      expect(findGlDisclosureDropdown().props('popperOptions')).toEqual({
        modifiers: [{ name: 'offset', options: { offset: [-147, 4] } }],
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

    it("sets the toggle ID and tooltip's target", () => {
      expect(findGlDisclosureDropdown().props('toggleId')).toBe(wrapper.vm.$options.toggleId);
      expect(findGlTooltip().props('target')).toBe(`#${wrapper.vm.$options.toggleId}`);
    });

    it('hides the tooltip when the dropdown is opened', async () => {
      findGlDisclosureDropdown().vm.$emit('shown');
      await nextTick();

      expect(findGlTooltip().exists()).toBe(false);
    });

    it('shows the tooltip when the dropdown is closed', async () => {
      findGlDisclosureDropdown().vm.$emit('shown');
      findGlDisclosureDropdown().vm.$emit('hidden');
      await nextTick();

      expect(findGlTooltip().exists()).toBe(true);
    });

    it('closes the dropdown when invite members modal is opened', () => {
      findInviteMembersTrigger().vm.$emit('modal-opened');
      expect(closeAndFocusMock).toHaveBeenCalled();
    });
  });
});
