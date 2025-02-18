import { GlPopover } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from 'jh_else_ce/groups/components/group_item.vue';
import ItemActions from '~/groups/components/item_actions.vue';
import VisibilityIconButton from '~/vue_shared/components/visibility_icon_button.vue';
import eventHub from '~/groups/event_hub';
import { getGroupItemMicrodata } from '~/groups/store/utils';
import * as urlUtilities from '~/lib/utils/url_utility';
import { ITEM_TYPE } from '~/groups/constants';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockParentGroupItem, mockChildren } from '../mock_data';

const createComponent = (
  propsData = { group: mockParentGroupItem, parentGroup: mockChildren[0] },
  provide = {
    currentGroupVisibility: VISIBILITY_LEVEL_PRIVATE_STRING,
  },
) => {
  return mountExtended(GroupItem, {
    propsData,
    components: { GroupFolder, GroupItem },
    provide,
  });
};

describe('GroupItemComponent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
    return waitForPromises();
  });

  const withMicrodata = (group) => ({
    ...group,
    microdata: getGroupItemMicrodata(group),
  });

  describe('computed', () => {
    describe('groupDomId', () => {
      it('should return ID string suffixed with group ID', () => {
        expect(wrapper.vm.groupDomId).toBe('group-55');
      });
    });

    describe('rowClass', () => {
      it('should return map of classes based on group details', () => {
        const classes = ['is-open', 'has-children', 'has-description', 'being-removed'];
        const { rowClass } = wrapper.vm;

        expect(Object.keys(rowClass).length).toBe(classes.length);
        Object.keys(rowClass).forEach((className) => {
          expect(classes.indexOf(className)).toBeGreaterThan(-1);
        });
      });
    });

    describe('hasChildren', () => {
      it('should return boolean value representing if group has any children present', () => {
        const group = { ...mockParentGroupItem };

        group.childrenCount = 5;
        group.hasChildren = true;
        wrapper = createComponent({ group });

        expect(wrapper.vm.hasChildren).toBe(true);
        wrapper.destroy();

        group.childrenCount = 0;
        group.hasChildren = false;
        wrapper = createComponent({ group });

        expect(wrapper.vm.hasChildren).toBe(false);
        wrapper.destroy();
      });
    });

    describe('hasAvatar', () => {
      it('should return boolean value representing if group has any avatar present', () => {
        const group = { ...mockParentGroupItem };

        group.avatarUrl = null;
        wrapper = createComponent({ group });

        expect(wrapper.vm.hasAvatar).toBe(false);
        wrapper.destroy();

        group.avatarUrl = '/uploads/group_avatar.png';
        wrapper = createComponent({ group });

        expect(wrapper.vm.hasAvatar).toBe(true);
        wrapper.destroy();
      });
    });

    describe('isGroup', () => {
      it('should return boolean value representing if group item is of type `group` or not', () => {
        const group = { ...mockParentGroupItem };

        group.type = 'group';
        wrapper = createComponent({ group });

        expect(wrapper.vm.isGroup).toBe(true);
        wrapper.destroy();

        group.type = 'project';
        group.lastActivityAt = '2017-04-09T18:40:39.101Z';
        wrapper = createComponent({ group });

        expect(wrapper.vm.isGroup).toBe(false);
        wrapper.destroy();
      });
    });
  });

  describe('visibilityIconButton', () => {
    describe('if item represents a group', () => {
      it('should display the visibility icon with appropriate props', () => {
        const group = { ...mockParentGroupItem };

        group.type = 'group';
        group.visibility = VISIBILITY_LEVEL_PRIVATE_STRING;
        wrapper = createComponent({ group });

        expect(wrapper.findComponent(VisibilityIconButton).props()).toEqual({
          isGroup: true,
          tooltipPlacement: 'bottom',
          visibilityLevel: VISIBILITY_LEVEL_PRIVATE_STRING,
        });
      });
    });

    describe('if item represents a project', () => {
      it('should display the visibility icon with appropriate props', () => {
        const group = { ...mockParentGroupItem };

        group.type = 'project';
        group.lastActivityAt = '2017-04-09T18:40:39.101Z';
        group.visibility = VISIBILITY_LEVEL_PRIVATE_STRING;
        wrapper = createComponent({ group });

        expect(wrapper.findComponent(VisibilityIconButton).props()).toEqual({
          isGroup: false,
          tooltipPlacement: 'bottom',
          visibilityLevel: VISIBILITY_LEVEL_PRIVATE_STRING,
        });
      });
    });
  });

  describe('methods', () => {
    describe('onClickRowGroup', () => {
      let event;

      beforeEach(() => {
        const classList = {
          contains() {
            return false;
          },
        };

        event = {
          target: {
            classList,
            parentElement: {
              classList,
            },
          },
        };
      });

      it('should emit `toggleChildren` event when expand is clicked on a group and it has children present', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        wrapper.vm.onClickRowGroup(event);

        expect(eventHub.$emit).toHaveBeenCalledWith('toggleChildren', wrapper.vm.group);
      });

      it('should navigate page to group homepage if group does not have any children present', () => {
        jest.spyOn(urlUtilities, 'visitUrl').mockImplementation();
        const group = { ...mockParentGroupItem };
        group.childrenCount = 0;
        group.hasChildren = false;
        wrapper = createComponent({ group });
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        wrapper.vm.onClickRowGroup(event);

        expect(eventHub.$emit).not.toHaveBeenCalled();
        expect(urlUtilities.visitUrl).toHaveBeenCalledWith(wrapper.vm.group.relativePath);
      });
    });
  });

  describe('template', () => {
    let group = null;

    describe('for a group pending deletion', () => {
      beforeEach(() => {
        group = { ...mockParentGroupItem, pendingRemoval: true };
        wrapper = createComponent({ group });
      });

      it('renders the group pending deletion badge', () => {
        const badgeEl = wrapper.vm.$el.querySelector('.badge-warning');

        expect(badgeEl).toBeDefined();
        expect(badgeEl.innerHTML).toContain('Pending deletion');
      });
    });

    describe('for a group not scheduled for deletion', () => {
      beforeEach(() => {
        group = { ...mockParentGroupItem, pendingRemoval: false };
        wrapper = createComponent({ group });
      });

      it('does not render the group pending deletion badge', () => {
        const groupTextContainer = wrapper.vm.$el.querySelector('.group-text-container');

        expect(groupTextContainer).not.toContain('Pending deletion');
      });

      it('renders `item-actions` component and passes correct props to it', () => {
        wrapper = createComponent({
          group: mockParentGroupItem,
          parentGroup: mockChildren[0],
          action: 'subgroups_and_projects',
        });
        const itemActionsComponent = wrapper.findComponent(ItemActions);

        expect(itemActionsComponent.exists()).toBe(true);
        expect(itemActionsComponent.props()).toEqual({
          group: mockParentGroupItem,
          parentGroup: mockChildren[0],
          action: 'subgroups_and_projects',
        });
      });
    });

    it('should render component template correctly', () => {
      const visibilityIconEl = wrapper.vm.$el.querySelector(
        '[data-testid="group-visibility-icon"]',
      );

      const { vm } = wrapper;

      expect(vm.$el.getAttribute('id')).toBe('group-55');
      expect(vm.$el.classList.contains('group-row')).toBe(true);

      expect(vm.$el.querySelector('.group-row-contents')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .controls')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .stats')).toBeDefined();

      expect(vm.$el.querySelector('.folder-toggle-wrap')).toBeDefined();
      expect(vm.$el.querySelector('.folder-toggle-wrap .item-type-icon')).toBeDefined();

      expect(vm.$el.querySelector('.avatar-container')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container a.no-expand')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container .avatar')).toBeDefined();

      expect(vm.$el.querySelector('.title')).toBeDefined();
      expect(vm.$el.querySelector('.title a.no-expand')).toBeDefined();

      expect(visibilityIconEl).not.toBe(null);

      expect(vm.$el.querySelector('.access-type')).toBeDefined();
      expect(vm.$el.querySelector('.description')).toBeDefined();

      expect(vm.$el.querySelector('.group-list-tree')).toBeDefined();
    });
  });

  describe('schema.org props', () => {
    describe('when showSchemaMarkup is disabled on the group', () => {
      it.each(['itemprop', 'itemtype', 'itemscope'])('does not set %s', (attr) => {
        expect(wrapper.attributes(attr)).toBeUndefined();
      });
    });

    describe('when group has microdata', () => {
      beforeEach(() => {
        const group = withMicrodata({
          ...mockParentGroupItem,
          avatarUrl: 'http://foo.bar',
          description: 'Foo Bar',
        });

        wrapper = createComponent({ group });
      });

      it.each`
        attr          | value
        ${'itemtype'} | ${'https://schema.org/Organization'}
        ${'itemprop'} | ${'subOrganization'}
      `('does set correct $attr', ({ attr, value } = {}) => {
        expect(wrapper.attributes(attr)).toBe(value);
      });

      it.each`
        selector                               | propValue
        ${'img'}                               | ${'logo'}
        ${'[data-testid="group-name"]'}        | ${'name'}
        ${'[data-testid="group-description"]'} | ${'description'}
      `('does set correct $selector', ({ selector, propValue } = {}) => {
        expect(wrapper.find(selector).attributes('itemprop')).toBe(propValue);
      });
    });
  });

  describe('visibility warning popover', () => {
    const findPopover = () => wrapper.findComponent(GlPopover);

    const itDoesNotRenderVisibilityWarningPopover = () => {
      it('does not render visibility warning popover', () => {
        expect(findPopover().exists()).toBe(false);
      });
    };

    describe('when showing groups', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      itDoesNotRenderVisibilityWarningPopover();
    });

    describe('when `action` prop is not `shared`', () => {
      beforeEach(() => {
        wrapper = createComponent({
          group: mockParentGroupItem,
          parentGroup: mockChildren[0],
          action: 'subgroups_and_projects',
        });
      });

      itDoesNotRenderVisibilityWarningPopover();
    });

    describe('when showing projects', () => {
      describe.each`
        itemVisibility                      | currentGroupVisibility              | isPopoverShown
        ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${false}
        ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${false}
        ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${false}
        ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${false}
        ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${true}
        ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${true}
        ${VISIBILITY_LEVEL_PRIVATE_STRING}  | ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${false}
        ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${false}
        ${VISIBILITY_LEVEL_PUBLIC_STRING}   | ${VISIBILITY_LEVEL_INTERNAL_STRING} | ${true}
      `(
        'when item visibility is $itemVisibility and parent group visibility is $currentGroupVisibility',
        ({ itemVisibility, currentGroupVisibility, isPopoverShown }) => {
          beforeEach(() => {
            wrapper = createComponent(
              {
                group: {
                  ...mockParentGroupItem,
                  visibility: itemVisibility,
                  type: ITEM_TYPE.PROJECT,
                },
                parentGroup: mockChildren[0],
                action: 'shared',
              },
              {
                currentGroupVisibility,
              },
            );
          });

          if (isPopoverShown) {
            it('renders visibility warning popover with `Learn more` link', () => {
              const popover = extendedWrapper(findPopover());

              expect(popover.exists()).toBe(true);

              expect(
                popover.findByRole('link', { name: GroupItem.i18n.learnMore }).attributes('href'),
              ).toBe(helpPagePath('user/project/members/sharing_projects_groups'));
            });
          } else {
            itDoesNotRenderVisibilityWarningPopover();
          }
        },
      );
    });

    it('sets up popover `target` prop correctly', () => {
      wrapper = createComponent({
        group: {
          ...mockParentGroupItem,
          visibility: VISIBILITY_LEVEL_PUBLIC_STRING,
          type: ITEM_TYPE.PROJECT,
        },
        parentGroup: mockChildren[0],
        action: 'shared',
      });

      expect(findPopover().props('target')()).toEqual(
        wrapper.findByRole('button', { name: GroupItem.i18n.popoverTitle }).element,
      );
    });
  });
});
