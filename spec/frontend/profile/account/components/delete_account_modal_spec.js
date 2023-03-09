import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import { nextTick } from 'vue';

import { TEST_HOST } from 'helpers/test_constants';
import deleteAccountModal from '~/profile/account/components/delete_account_modal.vue';

const GlModalStub = {
  name: 'gl-modal-stub',
  template: `
    <div>
      <slot></slot>
    </div>
  `,
};

describe('DeleteAccountModal component', () => {
  const actionUrl = `${TEST_HOST}/delete/user`;
  const username = 'hasnoname';
  let wrapper;
  let vm;

  const createWrapper = (options = {}) => {
    wrapper = mount(
      deleteAccountModal,
      merge(
        {},
        {
          propsData: {
            actionUrl,
            username,
          },
          stubs: {
            GlModal: GlModalStub,
          },
        },
        options,
      ),
    );
    vm = wrapper.vm;
  };

  const findElements = () => {
    const confirmation = vm.confirmWithPassword ? 'password' : 'username';
    return {
      form: vm.$refs.form,
      input: vm.$el.querySelector(`[name="${confirmation}"]`),
    };
  };
  const findModal = () => wrapper.findComponent(GlModalStub);

  describe('with password confirmation', () => {
    beforeEach(async () => {
      createWrapper({
        propsData: {
          confirmWithPassword: true,
        },
      });

      vm.isOpen = true;

      await nextTick();
    });

    it('does not accept empty password', async () => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = '';
      input.dispatchEvent(new Event('input'));

      await nextTick();
      expect(vm.enteredPassword).toBe(input.value);
      expect(findModal().attributes('ok-disabled')).toBe('true');
      findModal().vm.$emit('primary');

      expect(form.submit).not.toHaveBeenCalled();
    });

    it('submits form with password', async () => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = 'anything';
      input.dispatchEvent(new Event('input'));

      await nextTick();
      expect(vm.enteredPassword).toBe(input.value);
      expect(findModal().attributes('ok-disabled')).toBeUndefined();
      findModal().vm.$emit('primary');

      expect(form.submit).toHaveBeenCalled();
    });
  });

  describe('with username confirmation', () => {
    beforeEach(async () => {
      createWrapper({
        propsData: {
          confirmWithPassword: false,
        },
      });

      vm.isOpen = true;

      await nextTick();
    });

    it('does not accept wrong username', async () => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = 'this is wrong';
      input.dispatchEvent(new Event('input'));

      await nextTick();
      expect(vm.enteredUsername).toBe(input.value);
      expect(findModal().attributes('ok-disabled')).toBe('true');
      findModal().vm.$emit('primary');

      expect(form.submit).not.toHaveBeenCalled();
    });

    it('submits form with correct username', async () => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = username;
      input.dispatchEvent(new Event('input'));

      await nextTick();
      expect(vm.enteredUsername).toBe(input.value);
      expect(findModal().attributes('ok-disabled')).toBeUndefined();
      findModal().vm.$emit('primary');

      expect(form.submit).toHaveBeenCalled();
    });
  });
});
