import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import {
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_PIPELINE,
  TODO_TARGET_TYPE_SSH_KEY,
  TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED,
  TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED,
  TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED,
} from '~/todos/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { DESIGN_TODO, MR_BUILD_FAILED_TODO } from '../mock_data';

describe('TodoItemTitle', () => {
  let wrapper;

  const mockToDo = {
    author: {
      id: '2',
      name: 'John Doe',
      webUrl: '/john',
      avatarUrl: '/avatar.png',
    },
    action: TODO_ACTION_TYPE_ASSIGNED,
    targetEntity: {
      name: 'Target title',
      webPath: '/flightjs/Flight/-/issues/1',
    },
    targetType: TODO_TARGET_TYPE_ISSUE,
  };

  const createComponent = (todo = mockToDo, otherProps = {}) => {
    wrapper = extendedWrapper(
      shallowMount(TodoItemTitle, {
        propsData: {
          currentUserId: '1',
          todo,
          ...otherProps,
        },
      }),
    );
  };

  it('renders target title', () => {
    createComponent();
    expect(wrapper.text()).toContain('Target title');
  });

  describe('todos title', () => {
    it.each([
      ['to-do for MR', 'Update file .gitlab-ci.yml · Flightjs / Flight !17', MR_BUILD_FAILED_TODO],
      [
        'to-do for design',
        'Important issue › Screenshot_2024-11-22_at_16.11.25.png · Flightjs / Flight #35',
        DESIGN_TODO,
      ],
      [
        'to-do for duo pro access granted',
        'Getting started with GitLab Duo',
        { ...mockToDo, action: TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED },
      ],
    ])(`renders %s as %s`, (_a, b, c) => {
      createComponent(c);
      expect(wrapper.findByTestId('todo-title').text()).toBe(b);
    });
  });

  describe('correct icon for targetType', () => {
    it.each`
      targetType                        | icon               | showsIcon
      ${TODO_TARGET_TYPE_ALERT}         | ${'status-alert'}  | ${true}
      ${TODO_TARGET_TYPE_DESIGN}        | ${'media'}         | ${true}
      ${TODO_TARGET_TYPE_MERGE_REQUEST} | ${'merge-request'} | ${true}
      ${TODO_TARGET_TYPE_PIPELINE}      | ${'pipeline'}      | ${true}
      ${TODO_TARGET_TYPE_SSH_KEY}       | ${'token'}         | ${true}
      ${'UNKNOWN_TYPE'}                 | ${''}              | ${false}
    `('renders "$icon" for the "$targetType" type', ({ targetType, icon, showsIcon }) => {
      createComponent({ ...mockToDo, targetType });

      const glIcon = wrapper.findComponent(GlIcon);
      expect(glIcon.exists()).toBe(showsIcon);

      if (showsIcon) {
        expect(glIcon.props('name')).toBe(icon);
      }
    });
  });

  describe('correct icon for action', () => {
    it.each`
      action                                            | icon      | showsIcon
      ${TODO_ACTION_TYPE_DUO_PRO_ACCESS_GRANTED}        | ${'book'} | ${true}
      ${TODO_ACTION_TYPE_DUO_ENTERPRISE_ACCESS_GRANTED} | ${'book'} | ${true}
      ${TODO_ACTION_TYPE_DUO_CORE_ACCESS_GRANTED}       | ${'book'} | ${true}
    `('renders "$icon" for the "$action" action', ({ action, icon, showsIcon }) => {
      createComponent({ ...mockToDo, action });

      const glIcon = wrapper.findComponent(GlIcon);
      expect(glIcon.exists()).toBe(showsIcon);

      if (showsIcon) {
        expect(glIcon.props('name')).toBe(icon);
      }
    });
  });

  describe('work item todo', () => {
    const workItemTodo = {
      ...mockToDo,
      targetType: TODO_TARGET_TYPE_ISSUE,
      targetEntity: {
        name: 'My Epic',
        webPath: '/groups/gitlab-duo/-/work_items/3',
        workItemType: { name: 'Epic', iconName: 'epic' },
      },
    };

    it.each`
      workItemType    | iconName
      ${'Epic'}       | ${'epic'}
      ${'Task'}       | ${'issue-type-task'}
      ${'Objective'}  | ${'issue-type-objective'}
      ${'Key Result'} | ${'issue-type-keyresult'}
    `('renders correct WorkItemTypeIcon for $workItemType', ({ workItemType, iconName }) => {
      createComponent({
        ...workItemTodo,
        targetEntity: {
          ...workItemTodo.targetEntity,
          workItemType: { name: workItemType, iconName },
        },
      });

      const workItemIcon = wrapper.findComponent(WorkItemTypeIcon);
      expect(workItemIcon.props('workItemType')).toBe(workItemType);
      expect(workItemIcon.props('typeIconName')).toBe(iconName);
    });

    it('does not render WorkItemTypeIcon for non-work-item todos', () => {
      createComponent({
        ...mockToDo,
        targetType: TODO_TARGET_TYPE_ISSUE,
        targetEntity: {
          name: 'A regular issue',
          webPath: '/flightjs/Flight/-/issues/5',
        },
      });

      const workItemIcon = wrapper.findComponent(WorkItemTypeIcon);
      expect(workItemIcon.exists()).toBe(false);
    });
  });
});
