import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlAvatarLabeled, GlIcon, GlBadge } from '@gitlab/ui';
import GroupsListItemPlanBadge from 'ee_component/vue_shared/components/groups_list/groups_list_item_plan_badge.vue';
import axios from '~/lib/utils/axios_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemInactiveBadge from '~/vue_shared/components/groups_list/group_list_item_inactive_badge.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import GroupListItemActions from '~/vue_shared/components/groups_list/group_list_item_actions.vue';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_PUBLIC_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { renderDeleteSuccessToast } from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import { groups } from './mock_data';

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

jest.mock('~/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/groups_list/utils'),
  renderDeleteSuccessToast: jest.fn(),
  deleteParams: jest.fn(() => MOCK_DELETE_PARAMS),
}));
jest.mock('~/alert');

describe('GroupsListItem', () => {
  let wrapper;
  let axiosMock;

  const [group] = groups;

  const defaultPropsData = { group };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(GroupsListItem, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      scopedSlots: {
        'children-toggle': '<div data-testid="children-toggle"></div>',
        children: '<div data-testid="children"></div>',
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findGroupDescription = () => wrapper.findByTestId('description');
  const findVisibilityIcon = () => findAvatarLabeled().findComponent(GlIcon);
  const findGroupListItemActions = () => wrapper.findComponent(GroupListItemActions);
  const findDeleteConfirmationModal = () => wrapper.findComponent(GroupListItemDeleteModal);
  const findPreventDeleteModal = () => wrapper.findComponent(GroupListItemPreventDeleteModal);
  const findLeaveModal = () => wrapper.findComponent(GroupListItemLeaveModal);
  const findAccessLevelBadge = () => wrapper.findByTestId('user-access-role');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findSubgroupCount = () => wrapper.findByTestId('subgroups-count');
  const findProjectsCount = () => wrapper.findByTestId('projects-count');
  const findMembersCount = () => wrapper.findByTestId('members-count');
  const findStorageSize = () => wrapper.findByTestId('storage-size');

  const findInactiveBadge = () => wrapper.findComponent(GroupListItemInactiveBadge);

  const deleteModalFireConfirmEvent = async () => {
    findDeleteConfirmationModal().vm.$emit('confirm', {
      preventDefault: jest.fn(),
    });
    await nextTick();
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('renders group avatar', () => {
    createComponent();

    const avatarLabeled = findAvatarLabeled();

    expect(avatarLabeled.props()).toMatchObject({
      label: group.fullName,
      labelLink: group.relativeWebUrl,
    });

    expect(avatarLabeled.attributes()).toMatchObject({
      'entity-id': group.id.toString(),
      'entity-name': group.fullName,
      src: group.avatarUrl,
      shape: 'rect',
    });
  });

  it('renders visibility icon with tooltip', () => {
    createComponent();

    const icon = findAvatarLabeled().findComponent(GlIcon);
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_PUBLIC_STRING]);
    expect(tooltip.value).toBe(GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_PUBLIC_STRING]);
  });

  it('renders subgroup count', () => {
    createComponent();

    expect(findSubgroupCount().props()).toMatchObject({
      tooltipText: 'Subgroups',
      iconName: 'subgroup',
      stat: group.descendantGroupsCount.toString(),
    });
  });

  describe('when subgroup count is not available', () => {
    it.each([undefined, null])('does not render subgroup count', (descendantGroupsCount) => {
      createComponent({ propsData: { group: { ...group, descendantGroupsCount } } });

      expect(findSubgroupCount().exists()).toBe(false);
    });
  });

  it('renders projects count', () => {
    createComponent();

    expect(findProjectsCount().props()).toMatchObject({
      tooltipText: 'Projects',
      iconName: 'project',
      stat: group.projectsCount.toString(),
    });
  });

  describe('when projects count is not available', () => {
    it.each([undefined, null])('does not render projects count', (projectsCount) => {
      createComponent({ propsData: { group: { ...group, projectsCount } } });

      expect(findProjectsCount().exists()).toBe(false);
    });
  });

  it('renders members count', () => {
    createComponent();

    expect(findMembersCount().props()).toMatchObject({
      tooltipText: 'Direct members',
      iconName: 'users',
      stat: group.groupMembersCount.toString(),
    });
  });

  describe('when members count is not available', () => {
    it.each([undefined, null])('does not render members count', (groupMembersCount) => {
      createComponent({ propsData: { group: { ...group, groupMembersCount } } });

      expect(findMembersCount().exists()).toBe(false);
    });
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

  it('renders access level badge', () => {
    createComponent();

    expect(findAvatarLabeled().findComponent(GlBadge).text()).toBe(
      ACCESS_LEVEL_LABELS[group.accessLevel.integerValue],
    );
  });

  describe.each`
    accessLevel
    ${{ accessLevel: undefined }}
    ${{ accessLevel: { integerValue: null } }}
    ${{ accessLevel: { integerValue: ACCESS_LEVEL_NO_ACCESS_INTEGER } }}
  `('when access level is $accessLevel', ({ accessLevel }) => {
    beforeEach(() => {
      createComponent({
        propsData: { group: { ...group, accessLevel } },
      });
    });

    it('does not render level role badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  describe('when group does not have projectStatistics key', () => {
    const { projectStatistics, ...groupWithoutProjectStatistics } = group;
    beforeEach(() => {
      createComponent({
        propsData: { group: groupWithoutProjectStatistics },
      });
    });

    it('does not render storage size', () => {
      expect(findStorageSize().exists()).toBe(false);
    });
  });

  describe('when group has projectStatistics key', () => {
    it('renders storage size in human size', () => {
      createComponent();

      expect(findStorageSize().text()).toBe('100.00 MiB');
    });

    describe('when storage size is null', () => {
      beforeEach(() => {
        createComponent({
          propsData: { group: { ...group, projectStatistics: { storageSize: null } } },
        });
      });

      it('renders 0 B', () => {
        expect(findStorageSize().text()).toBe('0 B');
      });
    });
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

  describe('when group has actions', () => {
    beforeEach(createComponent);

    it('renders list item actions with correct props', () => {
      expect(findGroupListItemActions().props()).toMatchObject({ group });
    });

    describe('when list item actions emits refetch', () => {
      it('emits refetch', () => {
        findGroupListItemActions().vm.$emit('refetch');

        expect(wrapper.emitted('refetch')).toEqual([[]]);
      });
    });

    describe('when list item actions emits leave', () => {
      it('shows leave modal', async () => {
        findGroupListItemActions().vm.$emit('leave');
        await nextTick();

        expect(findLeaveModal().props('visible')).toBe(true);
      });

      describe('when leave modal emits visibility change', () => {
        it("updates the modal's visibility prop", async () => {
          findLeaveModal().vm.$emit('change', false);

          await nextTick();

          expect(findLeaveModal().props('visible')).toBe(false);
        });
      });

      describe('when leave modal emits success event', () => {
        it('emits refetch event', () => {
          findLeaveModal().vm.$emit('success');

          expect(wrapper.emitted('refetch')).toEqual([[]]);
        });
      });
    });

    describe('when list item actions emits delete', () => {
      describe('when group is linked to a subscription', () => {
        const groupLinkedToSubscription = {
          ...group,
          isLinkedToSubscription: true,
        };

        beforeEach(async () => {
          createComponent({
            propsData: {
              group: groupLinkedToSubscription,
            },
          });

          findGroupListItemActions().vm.$emit('delete');
          await nextTick();
        });

        it('displays prevent delete modal', () => {
          expect(findPreventDeleteModal().props()).toMatchObject({
            visible: true,
          });
        });

        describe('when change is fired', () => {
          beforeEach(() => {
            findPreventDeleteModal().vm.$emit('change', false);
          });

          it('updates visibility prop', () => {
            expect(findPreventDeleteModal().props('visible')).toBe(false);
          });
        });
      });

      describe('when group can be deleted', () => {
        beforeEach(async () => {
          createComponent({
            propsData: {
              group,
            },
          });

          findGroupListItemActions().vm.$emit('delete');
          await nextTick();
        });

        it('displays confirmation modal with correct props', () => {
          expect(findDeleteConfirmationModal().props()).toMatchObject({
            visible: true,
            phrase: group.fullName,
            confirmLoading: false,
          });
        });

        describe('when deletion is confirmed', () => {
          describe('when API call is successful', () => {
            it('calls DELETE on group path, properly sets loading state, and emits refetch event', async () => {
              axiosMock.onDelete(group.relativeWebUrl).reply(200);

              await deleteModalFireConfirmEvent();
              expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(true);

              await waitForPromises();

              expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
              expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(false);
              expect(wrapper.emitted('refetch')).toEqual([[]]);
              expect(renderDeleteSuccessToast).toHaveBeenCalledWith(group);
              expect(createAlert).not.toHaveBeenCalled();
            });
          });

          describe('when API call is not successful', () => {
            it('calls DELETE on group path, properly sets loading state, and shows error alert', async () => {
              axiosMock.onDelete(group.relativeWebUrl).networkError();

              await deleteModalFireConfirmEvent();
              expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(true);

              await waitForPromises();

              expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
              expect(findDeleteConfirmationModal().props('confirmLoading')).toBe(false);
              expect(wrapper.emitted('refetch')).toBeUndefined();
              expect(createAlert).toHaveBeenCalledWith({
                message:
                  'An error occurred deleting the group. Please refresh the page to try again.',
                error: new Error('Network Error'),
                captureError: true,
              });
              expect(renderDeleteSuccessToast).not.toHaveBeenCalled();
            });
          });
        });

        describe('when change is fired', () => {
          beforeEach(() => {
            findDeleteConfirmationModal().vm.$emit('change', false);
          });

          it('updates visibility prop', () => {
            expect(findDeleteConfirmationModal().props('visible')).toBe(false);
          });
        });
      });

      describe('when group can be deleted immediately', () => {
        beforeEach(async () => {
          createComponent({
            propsData: {
              group: {
                ...group,
                markedForDeletion: true,
                isSelfDeletionInProgress: true,
                isSelfDeletionScheduled: false,
              },
            },
          });

          findGroupListItemActions().vm.$emit('delete');
          await nextTick();
        });

        it('displays confirmation modal with correct props', () => {
          expect(findDeleteConfirmationModal().props()).toMatchObject({
            visible: true,
            phrase: group.fullName,
            confirmLoading: false,
          });
        });
      });
    });
  });

  describe('when group does not have actions', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          group: {
            ...group,
            availableActions: [],
          },
        },
      });
    });

    it('does not render list item actions', () => {
      expect(findGroupListItemActions().exists()).toBe(false);
    });

    it('does not display confirmation modal', () => {
      expect(findDeleteConfirmationModal().exists()).toBe(false);
    });
  });

  describe.each`
    timestampType                | expectedText | expectedTimeProp
    ${TIMESTAMP_TYPE_CREATED_AT} | ${'Created'} | ${group.createdAt}
    ${TIMESTAMP_TYPE_UPDATED_AT} | ${'Updated'} | ${group.updatedAt}
    ${undefined}                 | ${'Created'} | ${group.createdAt}
  `(
    'when `timestampType` prop is $timestampType',
    ({ timestampType, expectedText, expectedTimeProp }) => {
      beforeEach(() => {
        createComponent({
          propsData: {
            timestampType,
          },
        });
      });

      it('displays correct text and passes correct `time` prop to `TimeAgoTooltip`', () => {
        expect(wrapper.findByText(expectedText).exists()).toBe(true);
        expect(findTimeAgoTooltip().props('time')).toBe(expectedTimeProp);
      });
    },
  );

  describe('when timestamp type is not available in group data', () => {
    beforeEach(() => {
      const { createdAt, ...groupWithoutCreatedAt } = group;
      createComponent({
        propsData: {
          group: groupWithoutCreatedAt,
        },
      });
    });

    it('does not render timestamp', () => {
      expect(findTimeAgoTooltip().exists()).toBe(false);
    });
  });

  it('renders listItemClass prop on first div in li element', () => {
    createComponent({ propsData: { listItemClass: 'foo' } });

    expect(wrapper.element.firstChild.classList).toContain('foo');
  });

  it('renders children-toggle slot', () => {
    createComponent();

    expect(wrapper.findByTestId('children-toggle').exists()).toBe(true);
  });

  it('renders children slot', () => {
    createComponent();

    expect(wrapper.findByTestId('children').exists()).toBe(true);
  });

  it('renders inactive badge', () => {
    createComponent();

    expect(findInactiveBadge().exists()).toBe(true);
  });

  it('renders plan badge', () => {
    createComponent();

    expect(wrapper.findComponent(GroupsListItemPlanBadge).exists()).toBe(true);
  });
});
