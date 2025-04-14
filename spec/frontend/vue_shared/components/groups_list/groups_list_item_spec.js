import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlAvatarLabeled, GlIcon, GlBadge } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupsListItem from '~/vue_shared/components/groups_list/groups_list_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import GroupListItemDeleteModal from 'ee_else_ce/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import {
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  GROUP_VISIBILITY_TYPE,
} from '~/visibility_level/constants';
import { ACCESS_LEVEL_LABELS, ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { renderDeleteSuccessToast } from 'ee_else_ce/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import { groups } from './mock_data';

const MOCK_DELETE_PARAMS = {
  testParam: true,
};

jest.mock('ee_else_ce/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('ee_else_ce/vue_shared/components/groups_list/utils'),
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
  const findListActions = () => wrapper.findComponent(ListActions);
  const findConfirmationModal = () => wrapper.findComponent(GroupListItemDeleteModal);
  const findPreventDeleteModal = () => wrapper.findComponent(GroupListItemPreventDeleteModal);
  const findAccessLevelBadge = () => wrapper.findByTestId('user-access-role');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const fireDeleteAction = () => findListActions().props('actions')[ACTION_DELETE].action();
  const deleteModalFireConfirmEvent = async () => {
    findConfirmationModal().vm.$emit('confirm', {
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
      labelLink: group.webUrl,
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

    expect(icon.props('name')).toBe(VISIBILITY_TYPE_ICON[VISIBILITY_LEVEL_INTERNAL_STRING]);
    expect(tooltip.value).toBe(GROUP_VISIBILITY_TYPE[VISIBILITY_LEVEL_INTERNAL_STRING]);
  });

  it('renders subgroup count', () => {
    createComponent();

    expect(wrapper.findByTestId('subgroups-count').props()).toMatchObject({
      tooltipText: 'Subgroups',
      iconName: 'subgroup',
      stat: group.descendantGroupsCount.toString(),
    });
  });

  it('renders projects count', () => {
    createComponent();

    expect(wrapper.findByTestId('projects-count').props()).toMatchObject({
      tooltipText: 'Projects',
      iconName: 'project',
      stat: group.projectsCount.toString(),
    });
  });

  it('renders members count', () => {
    createComponent();

    expect(wrapper.findByTestId('members-count').props()).toMatchObject({
      tooltipText: 'Direct members',
      iconName: 'users',
      stat: group.groupMembersCount.toString(),
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

  describe('when access level is not available', () => {
    const { accessLevel, ...groupWithoutAccessLevel } = group;
    beforeEach(() => {
      createComponent({
        propsData: { group: groupWithoutAccessLevel },
      });
    });

    it('does not render level role badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
    });
  });

  describe('when access level is `No access`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          group: { ...group, accessLevel: { integerValue: ACCESS_LEVEL_NO_ACCESS_INTEGER } },
        },
      });
    });

    it('does not render level role badge', () => {
      expect(findAccessLevelBadge().exists()).toBe(false);
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
    const groupWithDeleteAction = {
      ...group,
      actionLoadingStates: { [ACTION_DELETE]: false },
    };

    it('displays actions dropdown', () => {
      createComponent({
        propsData: {
          group: groupWithDeleteAction,
        },
      });

      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_EDIT]: {
            href: group.editPath,
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_EDIT, ACTION_DELETE],
      });
    });

    describe('when delete action is fired', () => {
      describe('when group is linked to a subscription', () => {
        const groupLinkedToSubscription = {
          ...groupWithDeleteAction,
          isLinkedToSubscription: true,
        };

        beforeEach(() => {
          createComponent({
            propsData: {
              group: groupLinkedToSubscription,
            },
          });
          fireDeleteAction();
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
        beforeEach(() => {
          createComponent({
            propsData: {
              group: groupWithDeleteAction,
            },
          });
          fireDeleteAction();
        });

        it('displays confirmation modal with correct props', () => {
          expect(findConfirmationModal().props()).toMatchObject({
            visible: true,
            phrase: groupWithDeleteAction.fullName,
            confirmLoading: false,
          });
        });

        describe('when deletion is confirmed', () => {
          describe('when API call is successful', () => {
            it('calls deleteProject, properly sets loading state, and emits refetch event', async () => {
              axiosMock.onDelete(`/${groupWithDeleteAction.fullPath}`).reply(200);

              await deleteModalFireConfirmEvent();
              expect(findConfirmationModal().props('confirmLoading')).toBe(true);

              await waitForPromises();

              expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
              expect(findConfirmationModal().props('confirmLoading')).toBe(false);
              expect(wrapper.emitted('refetch')).toEqual([[]]);
              expect(renderDeleteSuccessToast).toHaveBeenCalledWith(groupWithDeleteAction);
              expect(createAlert).not.toHaveBeenCalled();
            });
          });

          describe('when API call is not successful', () => {
            it('calls deleteProject, properly sets loading state, and shows error alert', async () => {
              axiosMock.onDelete(`/${groupWithDeleteAction.fullPath}`).networkError();

              await deleteModalFireConfirmEvent();
              expect(findConfirmationModal().props('confirmLoading')).toBe(true);

              await waitForPromises();

              expect(axiosMock.history.delete[0].params).toEqual(MOCK_DELETE_PARAMS);
              expect(findConfirmationModal().props('confirmLoading')).toBe(false);
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
            findConfirmationModal().vm.$emit('change', false);
          });

          it('updates visibility prop', () => {
            expect(findConfirmationModal().props('visible')).toBe(false);
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

    it('does not display actions dropdown', () => {
      expect(findListActions().exists()).toBe(false);
    });

    it('does not display confirmation modal', () => {
      expect(findConfirmationModal().exists()).toBe(false);
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
});
