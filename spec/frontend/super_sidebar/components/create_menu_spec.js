import { nextTick } from 'vue';
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlLink,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import { WORK_ITEM_TYPE_NAME_EPIC } from '~/work_items/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createNewMenuGroups, createNewMenuProjects } from '../mock_data';

describe('CreateMenu component', () => {
  let wrapper;
  const mockToast = jest.fn();

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlDisclosureDropdownGroups = () => wrapper.findAllComponents(GlDisclosureDropdownGroup);
  const findGlDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findInviteMembersTrigger = () => wrapper.findComponent(InviteMembersTrigger);
  const findCreateWorkItemModalTrigger = () => wrapper.findByTestId('new-work-item-trigger');
  const findCreateWorkItemModal = () => wrapper.findByTestId('new-work-item-modal');

  const createWrapper = ({ props = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(CreateMenu, {
      provide: {
        isImpersonating: false,
        fullPath: 'full-path',
        isGroup: false,
        workItemPlanningViewEnabled: true,
        ...provide,
      },
      propsData: {
        groups: createNewMenuGroups,
        ...props,
      },
      stubs: {
        InviteMembersTrigger,
        CreateWorkItemModal,
        GlDisclosureDropdown,
        GlEmoji: { template: '<div/>' },
        ...stubs,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $toast: { show: mockToast },
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
      mockToast.mockReset();
    });

    it('passes custom offset to the dropdown', () => {
      createWrapper();

      expect(findGlDisclosureDropdown().props('dropdownOffset')).toEqual({
        crossAxis: -158,
        mainAxis: 4,
      });
    });

    it("sets the toggle's label", () => {
      expect(findGlDisclosureDropdown().props('toggleText')).toBe('Create new…');
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
        createWrapper({ props: { groups: createNewMenuProjects } });

        expect(findCreateWorkItemModalTrigger().exists()).toBe(true);
      });

      it('does not render the modal by default', () => {
        createWrapper({ props: { groups: createNewMenuProjects } });

        expect(findCreateWorkItemModal().exists()).toBe(false);
      });

      it('shows modal when clicking work item dropdown item', async () => {
        createWrapper({ props: { groups: createNewMenuProjects } });

        findCreateWorkItemModalTrigger().vm.$emit('action');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(true);
        expect(findCreateWorkItemModal().props('isGroup')).toBe(false);
        expect(findCreateWorkItemModal().props('visible')).toBe(true);
        expect(findCreateWorkItemModal().props('hideButton')).toBe(true);
      });

      it('hides modal when hideModal event is emitted', async () => {
        createWrapper({ props: { groups: createNewMenuProjects } });

        findCreateWorkItemModalTrigger().vm.$emit('action');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(true);

        findCreateWorkItemModal().vm.$emit('hideModal');
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(false);
      });

      it('shows a toast when work item is created', async () => {
        const workItem = {
          workItemType: { name: 'Epic' },
          webUrl: 'https://gitlab.com/group/project/-/epics/123',
        };
        createWrapper({ props: { groups: createNewMenuProjects } });

        findCreateWorkItemModalTrigger().vm.$emit('action');
        await nextTick();

        findCreateWorkItemModal().vm.$emit('workItemCreated', workItem);
        await nextTick();

        expect(findCreateWorkItemModal().exists()).toBe(false);
        expect(mockToast).toHaveBeenCalledWith('Epic created', {
          autoHideDelay: 10000,
          action: {
            text: 'View details',
            onClick: expect.any(Function),
          },
        });
      });

      it('does not include href on dropdown item, to prevent it being rendered as an `<a>`', () => {
        createWrapper({
          provide: { workItemPlanningViewEnabled: false },
          props: { groups: createNewMenuProjects },
          stubs: { GlDisclosureDropdownItem },
        });

        expect(findCreateWorkItemModalTrigger().props('item')).toMatchObject({
          href: undefined,
        });
      });

      describe('link', () => {
        it('renders link', () => {
          createWrapper({
            provide: { workItemPlanningViewEnabled: false },
            props: { groups: createNewMenuProjects },
            stubs: { GlDisclosureDropdownItem },
          });

          expect(findCreateWorkItemModalTrigger().findComponent(GlLink).attributes('href')).toBe(
            'issues/new',
          );
        });

        it('opens modal when clicked', async () => {
          createWrapper({
            provide: { workItemPlanningViewEnabled: false },
            props: { groups: createNewMenuProjects },
            stubs: { GlDisclosureDropdownItem },
          });

          findCreateWorkItemModalTrigger()
            .findComponent(GlLink)
            .vm.$emit('click', { stopPropagation: jest.fn() });
          await nextTick();

          expect(findCreateWorkItemModal().exists()).toBe(true);
        });

        it('does not render when workItemPlanningViewEnabled=true', () => {
          createWrapper({
            provide: { workItemPlanningViewEnabled: true },
            props: { groups: createNewMenuProjects },
            stubs: { GlDisclosureDropdownItem },
          });

          expect(findCreateWorkItemModalTrigger().findComponent(GlLink).exists()).toBe(false);
        });
      });

      describe('allowed work item types', () => {
        it('returns empty array when group', async () => {
          createWrapper({ provide: { isGroup: true } });

          findCreateWorkItemModalTrigger().vm.$emit('action');
          await nextTick();

          expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([]);
        });

        it('returns Incident, Issue, and Task when project', async () => {
          createWrapper({ provide: { isGroup: false, workItemPlanningViewEnabled: true } });

          findCreateWorkItemModalTrigger().vm.$emit('action');
          await nextTick();

          expect(findCreateWorkItemModal().props('allowedWorkItemTypes')).toEqual([
            'Incident',
            'Issue',
            'Task',
          ]);
        });
      });

      describe('preselected work item type', () => {
        it.each`
          isGroup  | workItemPlanningViewEnabled | preselectedWorkItemType
          ${true}  | ${false}                    | ${WORK_ITEM_TYPE_NAME_EPIC}
          ${true}  | ${true}                     | ${null}
          ${false} | ${true}                     | ${null}
          ${false} | ${false}                    | ${null}
        `(
          'only returns Epic when group and workItemPlanningViewEnabled=false',
          async ({ isGroup, workItemPlanningViewEnabled, preselectedWorkItemType }) => {
            createWrapper({ provide: { isGroup, workItemPlanningViewEnabled } });

            findCreateWorkItemModalTrigger().vm.$emit('action');
            await nextTick();

            expect(findCreateWorkItemModal().props('preselectedWorkItemType')).toBe(
              preselectedWorkItemType,
            );
          },
        );
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
      expect(tooltip.value).toBe('Create new…');
    });
  });

  it('decreases the dropdown offset when impersonating a user', () => {
    createWrapper({ provide: { isImpersonating: true } });

    expect(findGlDisclosureDropdown().props('dropdownOffset')).toEqual({
      crossAxis: -158,
      mainAxis: 4,
    });
  });
});
