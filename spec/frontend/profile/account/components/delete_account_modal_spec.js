import Vue from 'vue';

import { TEST_HOST } from 'helpers/test_constants';
import { merge } from 'lodash';
import { mount } from '@vue/test-utils';
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    vm = null;
  });

  const findElements = () => {
    const confirmation = vm.confirmWithPassword ? 'password' : 'username';
    return {
      form: vm.$refs.form,
      input: vm.$el.querySelector(`[name="${confirmation}"]`),
    };
  };
  const findModal = () => wrapper.find(GlModalStub);

  describe('with password confirmation', () => {
    beforeEach(done => {
      createWrapper({
        propsData: {
          confirmWithPassword: true,
        },
      });

      vm.isOpen = true;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('does not accept empty password', done => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = '';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredPassword).toBe(input.value);
          expect(findModal().attributes('ok-disabled')).toBe('true');
          findModal().vm.$emit('primary');

          expect(form.submit).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('submits form with password', done => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = 'anything';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredPassword).toBe(input.value);
          expect(findModal().attributes('ok-disabled')).toBeUndefined();
          findModal().vm.$emit('primary');

          expect(form.submit).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with username confirmation', () => {
    beforeEach(done => {
      createWrapper({
        propsData: {
          confirmWithPassword: false,
        },
      });

      vm.isOpen = true;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('does not accept wrong username', done => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = 'this is wrong';
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredUsername).toBe(input.value);
          expect(findModal().attributes('ok-disabled')).toBe('true');
          findModal().vm.$emit('primary');

          expect(form.submit).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('submits form with correct username', done => {
      const { form, input } = findElements();
      jest.spyOn(form, 'submit').mockImplementation(() => {});
      input.value = username;
      input.dispatchEvent(new Event('input'));

      Vue.nextTick()
        .then(() => {
          expect(vm.enteredUsername).toBe(input.value);
          expect(findModal().attributes('ok-disabled')).toBeUndefined();
          findModal().vm.$emit('primary');

          expect(form.submit).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
