import { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createNewMenuGroups } from '../mock_data';

describe('CreateMenu component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlDisclosureDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);
  const findCreateWorkItemModalTrigger = () =>
    findGlDisclosureDropdownItems()
      .filter((item) => item.props('item').text === 'New epic')
      .at(0);
  const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);

  const createWrapper = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CreateMenu, {
      provide: {
        isImpersonating: false,
        fullPath: 'full-path',
        isGroup: false,
        ...provide,
      },
      propsData: {
        groups: createNewMenuGroups,
      },
      stubs: {
        InviteMembersTrigger,
        CreateWorkItemModal,
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
      expect(findGlDisclosureDropdown().props('toggleText')).toBe('Create new...');
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

    describe('create new work item modal', () => {
      it('renders work item menu item correctly', () => {
        expect(findCreateWorkItemModalTrigger().exists()).toBe(true);
      });

      it('does not render the modal by default', () => {
        expect(findCreateWorkItemModal().exists()).toBe(false);
      });

      it('shows modal when clicking work item dropdown item', async () => {
        findCreateWorkItemModalTrigger().vm.$emit('action');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(true);
        expect(findCreateWorkItemModal().props('isGroup')).toBe(true);
        expect(findCreateWorkItemModal().props('visible')).toBe(true);
        expect(findCreateWorkItemModal().props('hideButton')).toBe(true);
      });

      it('hides modal when hideModal event is emitted', async () => {
        findCreateWorkItemModalTrigger().vm.$emit('action');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(true);

        findCreateWorkItemModal().vm.$emit('hideModal');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(false);
      });
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
