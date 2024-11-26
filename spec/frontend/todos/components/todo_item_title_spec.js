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

describe('TodoItemTitle', () => {
  let wrapper;

  const createComponent = (todoExtras = {}, otherProps = {}) => {
    wrapper = shallowMount(TodoItemTitle, {
      propsData: {
        currentUserId: '1',
        todo: {
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
          ...todoExtras,
        },
        ...otherProps,
      },
    });
  };

  it('renders target title', () => {
    createComponent();
    expect(wrapper.text()).toContain('Target title');
  });

  describe('correct icon for targetType', () => {
    it.each`
      targetType                        | icon               | showsIcon
      ${TODO_TARGET_TYPE_ALERT}         | ${'status-alert'}  | ${true}
      ${TODO_TARGET_TYPE_DESIGN}        | ${'issues'}        | ${true}
      ${TODO_TARGET_TYPE_EPIC}          | ${'epic'}          | ${true}
      ${TODO_TARGET_TYPE_ISSUE}         | ${'issues'}        | ${true}
      ${TODO_TARGET_TYPE_MERGE_REQUEST} | ${'merge-request'} | ${true}
      ${TODO_TARGET_TYPE_PIPELINE}      | ${'pipeline'}      | ${true}
      ${TODO_TARGET_TYPE_PIPELINE}      | ${'pipeline'}      | ${true}
      ${TODO_TARGET_TYPE_SSH_KEY}       | ${'token'}         | ${true}
      ${'UNKNOWN_TYPE'}                 | ${''}              | ${false}
    `('renders "$icon" for the "$targetType" type', ({ targetType, icon, showsIcon }) => {
      createComponent({ targetType });

      const glIcon = wrapper.findComponent(GlIcon);
      expect(glIcon.exists()).toBe(showsIcon);

      if (showsIcon) {
        expect(glIcon.props('name')).toBe(icon);
      }
    });
  });
});
