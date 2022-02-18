import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AddUserModal from '~/user_lists/components/add_user_modal.vue';

describe('Add User Modal', () => {
  let wrapper;

  const click = (testId) => wrapper.find(`[data-testid="${testId}"]`).trigger('click');

  beforeEach(() => {
    wrapper = mount(AddUserModal, {
      propsData: { visible: true },
    });
  });

  it('should explain the format of user IDs to enter', () => {
    expect(wrapper.find('[data-testid="add-userids-description"]').text()).toContain(
      'Enter a comma separated list of user IDs',
    );
  });

  describe('events', () => {
    beforeEach(() => {
      wrapper.find('#add-user-ids').setValue('1, 2, 3, 4');
    });

    it('should emit the users entered when Add Users is clicked', () => {
      click('confirm-add-user-ids');
      expect(wrapper.emitted('addUsers')).toContainEqual(['1, 2, 3, 4']);
    });

    it('should clear the input after emitting', async () => {
      click('confirm-add-user-ids');
      await nextTick();

      expect(wrapper.find('#add-user-ids').element.value).toBe('');
    });

    it('should not emit the users entered if cancel is clicked', () => {
      click('cancel-add-user-ids');
      expect(wrapper.emitted('addUsers')).toBeUndefined();
    });

    it('should clear the input after cancelling', async () => {
      click('cancel-add-user-ids');
      await nextTick();

      expect(wrapper.find('#add-user-ids').element.value).toBe('');
    });
  });
});
