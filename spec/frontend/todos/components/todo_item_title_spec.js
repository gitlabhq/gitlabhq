import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import {
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_TARGET_TYPE_ALERT,
  TODO_TARGET_TYPE_DESIGN,
  TODO_TARGET_TYPE_EPIC,
  TODO_TARGET_TYPE_ISSUE,
  TODO_TARGET_TYPE_MERGE_REQUEST,
  TODO_TARGET_TYPE_PIPELINE,
  TODO_TARGET_TYPE_SSH_KEY,
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
      ${TODO_TARGET_TYPE_EPIC}          | ${'epic'}          | ${true}
      ${TODO_TARGET_TYPE_ISSUE}         | ${'issues'}        | ${true}
      ${TODO_TARGET_TYPE_MERGE_REQUEST} | ${'merge-request'} | ${true}
      ${TODO_TARGET_TYPE_PIPELINE}      | ${'pipeline'}      | ${true}
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
});
