import Vue from 'vue';
import Vuex from 'vuex';

import DeleteConfirmationModal from 'ee/vue_shared/license_management/components/delete_confirmation_modal.vue';
import { trimText } from 'spec/helpers/vue_component_helper';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { approvedLicense } from 'ee_spec/license_management/mock_data';

describe('DeleteConfirmationModal', () => {
  const Component = Vue.extend(DeleteConfirmationModal);

  let vm;
  let store;
  let actions;

  beforeEach(() => {
    actions = {
      resetLicenseInModal: jasmine.createSpy('resetLicenseInModal'),
      deleteLicense: jasmine.createSpy('deleteLicense'),
    };

    store = new Vuex.Store({
      state: {
        currentLicenseInModal: approvedLicense,
      },
      actions,
    });

    vm = mountComponentWithStore(Component, { store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('confirmationText', () => {
      it('returns information text with current license name in bold', () => {
        expect(vm.confirmationText).toBe(
          `You are about to remove the license, <strong>${
            approvedLicense.name
          }</strong>, from this project.`,
        );
      });
      it('escapes the license name', done => {
        const name = '<a href="#">BAD</a>';
        const nameEscaped = '&lt;a href=&quot;#&quot;&gt;BAD&lt;/a&gt;';

        store.replaceState({
          ...store.state,
          currentLicenseInModal: {
            ...approvedLicense,
            name,
          },
        });

        Vue.nextTick()
          .then(() => {
            expect(vm.confirmationText).toBe(
              `You are about to remove the license, <strong>${nameEscaped}</strong>, from this project.`,
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('interaction', () => {
    describe('triggering resetLicenseInModal on canceling', () => {
      it('by clicking the cancel button', () => {
        const linkEl = vm.$el.querySelector('.js-modal-cancel-action');
        linkEl.click();
        expect(actions.resetLicenseInModal).toHaveBeenCalled();
      });

      it('by clicking the X button', () => {
        const linkEl = vm.$el.querySelector('.js-modal-close-action');
        linkEl.click();
        expect(actions.resetLicenseInModal).toHaveBeenCalled();
      });
    });

    describe('triggering deleteLicense on canceling', () => {
      it('by clicking the confirmation button', () => {
        const linkEl = vm.$el.querySelector('.js-modal-primary-action');
        linkEl.click();
        expect(actions.deleteLicense).toHaveBeenCalledWith(
          jasmine.any(Object),
          store.state.currentLicenseInModal,
          undefined,
        );
      });
    });
  });

  describe('template', () => {
    it('renders modal title', () => {
      const headerEl = vm.$el.querySelector('.modal-title');
      expect(headerEl).not.toBeNull();
      expect(headerEl.innerText.trim()).toBe('Remove license?');
    });

    it('renders button in modal footer', () => {
      const footerButton = vm.$el.querySelector('.js-modal-primary-action');
      expect(footerButton).not.toBeNull();
      expect(footerButton.innerText.trim()).toBe('Remove license');
    });

    it('renders modal body', () => {
      const modalBody = vm.$el.querySelector('.modal-body');
      expect(modalBody).not.toBeNull();
      expect(trimText(modalBody.innerText)).toBe(
        `You are about to remove the license, ${approvedLicense.name}, from this project.`,
      );
    });
  });
});
