import { GlAvatarLabeled, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { groups } from './mock_data';

describe('GroupsListItem', () => {
  let wrapper;

  const [group] = groups;

  const defaultPropsData = { group };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(GroupsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findGroupDescription = () => wrapper.findByTestId('group-description');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);

  it('renders group avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: group.fullName,
      labelLink: group.webUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': group.id.toString(),
      'entity-name': group.fullName,
      shape: 'rect',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_INTERNAL_STRING]);
    expect(tooltip.value).toBe(GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_INTERNAL_STRING]);
  });

  it('renders subgroup count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('subgroups-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.subgroups);
    expect(countWrapper.text()).toBe(group.descendantGroupsCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('subgroup');
  });

  it('renders projects count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('projects-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.projects);
    expect(countWrapper.text()).toBe(group.projectsCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('project');
  });

  it('renders members count', () => {
    createComponent();

    const countWrapper = wrapper.findByTestId('members-count');
    const tooltip = getBinding(countWrapper.element, 'gl-tooltip');

    expect(tooltip.value).toBe(GroupsListItem.i18n.directMembers);
    expect(countWrapper.text()).toBe(group.groupMembersCount.toString());
    expect(countWrapper.findComponent(GlIcon).props('name')).toBe('users');
  });

  describe('when visibility is not provided', () => {
    it('does not render visibility icon', () => {
      const { visibility, ...groupWithoutVisibility } = group;
      createComponent({
        propsData: {
          group: groupWithoutVisibility,
        },
      });

      expect(findVisibilityIcon().exists()).toBe(false);
    });
  });

  it('renders access role badge', () => {
    createComponent();

    expect(findAvatarLabeled().findComponent(UserAccessRoleBadge).text()).toBe(
      ACCESS_LEVEL_LABELS[group.accessLevel.integerValue],
    );
  });

  describe('when group has a description', () => {
    it('renders description', () => {
      const descriptionHtml = '<p>Foo bar</p>';

      createComponent({
        propsData: {
          group: {
            ...group,
            descriptionHtml,
          },
        },
      });

      expect(findGroupDescription().element.innerHTML).toBe(descriptionHtml);
    });
  });

  describe('when group does not have a description', () => {
    it('does not render description', () => {
      createComponent({
        propsData: {
          group: {
            ...group,
            descriptionHtml: null,
          },
        },
      });

      expect(findGroupDescription().exists()).toBe(false);
    });
  });

  describe('when `showGroupIcon` prop is `true`', () => {
    describe('when `parent` attribute is `null`', () => {
      it('shows group icon', () => {
        createComponent({ propsData: { showGroupIcon: true } });

        expect(wrapper.findByTestId('group-icon').exists()).toBe(true);
      });
    });

    describe('when `parent` attribute is set', () => {
      it('shows subgroup icon', () => {
        createComponent({
          propsData: {
            showGroupIcon: true,
            group: {
              ...group,
              parent: {
                id: 'gid://gitlab/Group/35',
              },
            },
          },
        });

        expect(wrapper.findByTestId('subgroup-icon').exists()).toBe(true);
      });
    });
  });

  describe('when `showGroupIcon` prop is `false`', () => {
    it('does not show group icon', () => {
      createComponent();

      expect(wrapper.findByTestId('group-icon').exists()).toBe(false);
    });
  });
});
