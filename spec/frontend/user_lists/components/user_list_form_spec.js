import { mount } from '@vue/test-utils';
import Form from '~/user_lists/components/user_list_form.vue';
import { userList } from 'jest/feature_flags/mock_data';

describe('user_lists/components/user_list_form', () => {
  let wrapper;
  let input;

  beforeEach(() => {
    wrapper = mount(Form, {
      propsData: {
        cancelPath: '/cancel',
        saveButtonLabel: 'Save',
        userListsDocsPath: '/docs',
        userList,
      },
    });

    input = wrapper.find('[data-testid="user-list-name"]');
  });

  it('should set the name to the name of the given user list', () => {
    expect(input.element.value).toBe(userList.name);
  });

  it('should link to the user lists docs', () => {
    expect(wrapper.find('[data-testid="user-list-docs-link"]').attributes('href')).toBe('/docs');
  });

  it('should emit an updated user list when save is clicked', () => {
    input.setValue('test');
    wrapper.find('[data-testid="save-user-list"]').trigger('click');

    expect(wrapper.emitted('submit')).toEqual([[{ ...userList, name: 'test' }]]);
  });

  it('should set the cancel button to the passed url', () => {
    expect(wrapper.find('[data-testid="user-list-cancel"]').attributes('href')).toBe('/cancel');
  });
});
