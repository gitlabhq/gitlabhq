import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import TodoItemTitleHiddenBySaml from '~/todos/components/todo_item_title_hidden_by_saml.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('TodoItemTitle', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(shallowMount(TodoItemTitleHiddenBySaml));
  };

  it('renders target title', () => {
    createComponent();
    expect(wrapper.findByTestId('todo-title').text()).toEqual(
      'Select this item to sign in with SAML and view it.',
    );
  });

  it('renders "hidden" warning badge', () => {
    createComponent();

    const badge = wrapper.findComponent(GlBadge);
    expect(badge.text()).toBe('Hidden');
    expect(badge.props('variant')).toBe('warning');
    expect(badge.props('icon')).toBe('eye-slash');
  });
});
