import $ from 'jquery';
import Vue from 'vue';
import eventHub from 'ee/related_issues/event_hub';
import addIssuableForm from 'ee/related_issues/components/add_issuable_form.vue';

const issuable1 = {
  id: 200,
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  id: 201,
  reference: 'foo/bar#124',
  displayReference: '#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

describe('AddIssuableForm', () => {
  let AddIssuableForm;
  let vm;

  beforeEach(() => {
    AddIssuableForm = Vue.extend(addIssuableForm);
  });

  afterEach(() => {
    if (vm) {
      // Avoid any NPE errors from `@blur` being called
      // after `vm.$destroy` in tests, https://github.com/vuejs/vue/issues/5829
      document.activeElement.blur();

      vm.$destroy();
    }
  });

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          vm = new AddIssuableForm({
            propsData: {
              inputValue: '',
              pendingReferences: [],
            },
          }).$mount();
        });

        it('should have disabled submit button', () => {
          expect(vm.$refs.addButton.disabled).toBe(true);
          expect(vm.$refs.loadingIcon).toBeUndefined();
        });
      });

      describe('with input text', () => {
        beforeEach(() => {
          vm = new AddIssuableForm({
            propsData: {
              inputValue: 'foo',
              pendingReferences: [],
            },
          }).$mount();
        });

        it('should not have disabled submit button', () => {
          expect(vm.$refs.addButton.disabled).toBe(false);
        });
      });
    });

    describe('with references', () => {
      const inputValue = 'foo #123';

      beforeEach(() => {
        vm = new AddIssuableForm({
          propsData: {
            inputValue,
            pendingReferences: [
              issuable1.reference,
              issuable2.reference,
            ],
          },
        }).$mount();
      });

      it('should put input value in place', () => {
        expect(vm.$refs.input.value).toEqual(inputValue);
      });

      it('should render pending issuables items', () => {
        expect(vm.$el.querySelectorAll('.js-add-issuable-form-token-list-item').length).toEqual(2);
      });

      it('should not have disabled submit button', () => {
        expect(vm.$refs.addButton.disabled).toBe(false);
      });
    });

    describe('when submitting', () => {
      beforeEach(() => {
        vm = new AddIssuableForm({
          propsData: {
            inputValue: '',
            pendingReferences: [
              issuable1.reference,
              issuable2.reference,
            ],
            isSubmitting: true,
          },
        }).$mount();
      });

      it('should have disabled submit button with loading icon', () => {
        expect(vm.$refs.addButton.disabled).toBe(true);
        expect(vm.$refs.loadingIcon).toBeDefined();
      });
    });
  });

  describe('autocomplete', () => {
    describe('with autoCompleteSources', () => {
      beforeEach(() => {
        vm = new AddIssuableForm({
          propsData: {
            inputValue: '',
            autoCompleteSources: {
              issues: '/fake/issues/path',
            },
          },
        }).$mount();
      });

      it('shows placeholder text', () => {
        expect(vm.$refs.input.placeholder).toEqual('Paste issue link or <#issue id>');
      });

      it('has GfmAutoComplete', () => {
        expect(vm.gfmAutoComplete).toBeDefined();
      });
    });

    describe('with no autoCompleteSources', () => {
      beforeEach(() => {
        vm = new AddIssuableForm({
          propsData: {
            inputValue: '',
            autoCompleteSources: {},
          },
        }).$mount();
      });

      it('shows placeholder text', () => {
        expect(vm.$refs.input.placeholder).toEqual('Paste issue link');
      });

      it('does not have GfmAutoComplete', () => {
        expect(vm.gfmAutoComplete).not.toBeDefined();
      });
    });
  });

  describe('methods', () => {
    let addIssuableFormInputSpy;
    let addIssuableFormBlurSpy;
    let addIssuableFormSubmitSpy;
    let addIssuableFormCancelSpy;

    beforeEach(() => {
      addIssuableFormInputSpy = jasmine.createSpy('spy');
      addIssuableFormBlurSpy = jasmine.createSpy('spy');
      addIssuableFormSubmitSpy = jasmine.createSpy('spy');
      addIssuableFormCancelSpy = jasmine.createSpy('spy');
      eventHub.$on('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$on('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$on('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$on('addIssuableFormCancel', addIssuableFormCancelSpy);

      const el = document.createElement('div');
      // We need to append to body to get focus tests working
      document.body.appendChild(el);

      vm = new AddIssuableForm({
        propsData: {
          inputValue: '',
          pendingIssuables: [
            issuable1,
          ],
          autoCompleteSources: {
            issues: '/fake/issues/path',
          },
        },
      }).$mount(el);
    });

    afterEach(() => {
      eventHub.$off('addIssuableFormInput', addIssuableFormInputSpy);
      eventHub.$off('addIssuableFormBlur', addIssuableFormBlurSpy);
      eventHub.$off('addIssuableFormSubmit', addIssuableFormSubmitSpy);
      eventHub.$off('addIssuableFormCancel', addIssuableFormCancelSpy);
    });

    it('when clicking somewhere on the input wrapper should focus the input', (done) => {
      vm.onInputWrapperClick();

      setTimeout(() => {
        Vue.nextTick(() => {
          expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(true);
          expect(document.activeElement).toEqual(vm.$refs.input);

          done();
        });
      });
    });

    it('when filling in the input', () => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onInput();

      expect(addIssuableFormInputSpy).toHaveBeenCalledWith(newInputValue, newInputValue.length);
    });

    it('when blurring the input', (done) => {
      expect(addIssuableFormInputSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onBlur();

      setTimeout(() => {
        Vue.nextTick(() => {
          expect(vm.$refs.issuableFormWrapper.classList.contains('focus')).toEqual(false);
          expect(addIssuableFormBlurSpy).toHaveBeenCalledWith(newInputValue);

          done();
        });
      });
    });

    it('when using the autocomplete', (done) => {
      const $input = $(vm.$refs.input);

      vm.gfmAutoComplete.loadData($input, '#', [{
        id: 1,
        iid: 111,
        title: 'foo',
      }]);

      $input
        .val('#')
        .trigger('input')
        .trigger('click');

      $('.atwho-container li').trigger('click');

      setTimeout(() => {
        Vue.nextTick(() => {
          expect(vm.$refs.input.value).toEqual('');
          expect(addIssuableFormInputSpy.calls.count()).toEqual(1);

          done();
        });
      });
    });

    it('when submitting pending issues', () => {
      expect(addIssuableFormSubmitSpy).not.toHaveBeenCalled();

      const newInputValue = 'filling in things';
      vm.$refs.input.value = newInputValue;
      vm.onFormSubmit();

      expect(addIssuableFormSubmitSpy).toHaveBeenCalledWith(newInputValue);
    });

    it('when canceling form to collapse', () => {
      expect(addIssuableFormCancelSpy).not.toHaveBeenCalled();

      vm.onFormCancel();

      expect(addIssuableFormCancelSpy).toHaveBeenCalled();
    });
  });
});
