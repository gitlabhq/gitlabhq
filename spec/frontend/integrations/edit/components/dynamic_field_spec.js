import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import { mockField } from '../mock_data';

Vue.use(Vuex);

describe('DynamicField', () => {
  let wrapper;
  let store;

  const createComponent = (props, isInheriting = false, editable = true) => {
    store = new Vuex.Store({
      getters: {
        isInheriting: () => isInheriting,
        propsSource: () => {
          return {
            editable,
          };
        },
      },
    });

    wrapper = mount(DynamicField, {
      propsData: { ...mockField, ...props },
      store,
    });
  };

  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findGlFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findGlFormTextarea = () => wrapper.findComponent(GlFormTextarea);

  describe('template', () => {
    describe.each`
      isInheriting | editable | disabled      | readonly | checkboxLabel
      ${true}      | ${true}  | ${'disabled'} | ${true}  | ${undefined}
      ${false}     | ${true}  | ${undefined}  | ${false} | ${'Custom checkbox label'}
      ${true}      | ${false} | ${'disabled'} | ${true}  | ${undefined}
      ${false}     | ${false} | ${'disabled'} | ${false} | ${'Custom checkbox label'}
    `(
      'dynamic field, when isInheriting = `$isInheriting` and editable = `$editable`',
      ({ isInheriting, editable, disabled, readonly, checkboxLabel }) => {
        describe('type is checkbox', () => {
          beforeEach(() => {
            createComponent(
              {
                type: 'checkbox',
                checkboxLabel,
              },
              isInheriting,
              editable,
            );
          });

          it(`renders GlFormCheckbox, which ${isInheriting ? 'is' : 'is not'} disabled`, () => {
            expect(findGlFormCheckbox().exists()).toBe(true);
            expect(findGlFormCheckbox().find('[type=checkbox]').attributes('disabled')).toBe(
              disabled,
            );
          });

          it(`renders GlFormCheckbox with correct text content when checkboxLabel is ${checkboxLabel}`, () => {
            expect(findGlFormCheckbox().text()).toContain(checkboxLabel ?? mockField.title);
          });

          it('does not render other types of input', () => {
            expect(findGlFormSelect().exists()).toBe(false);
            expect(findGlFormTextarea().exists()).toBe(false);
            expect(findGlFormInput().exists()).toBe(false);
          });
        });

        describe('type is select', () => {
          beforeEach(() => {
            createComponent(
              {
                type: 'select',
                choices: [
                  ['all', 'All details'],
                  ['standard', 'Standard'],
                ],
              },
              isInheriting,
              editable,
            );
          });

          it(`renders GlFormSelect, which ${isInheriting ? 'is' : 'is not'} disabled`, () => {
            expect(findGlFormSelect().exists()).toBe(true);
            expect(findGlFormSelect().findAll('option')).toHaveLength(2);
            expect(findGlFormSelect().find('select').attributes('disabled')).toBe(disabled);
          });

          it('does not render other types of input', () => {
            expect(findGlFormCheckbox().exists()).toBe(false);
            expect(findGlFormTextarea().exists()).toBe(false);
            expect(findGlFormInput().exists()).toBe(false);
          });
        });

        describe('type is textarea', () => {
          beforeEach(() => {
            createComponent(
              {
                type: 'textarea',
              },
              isInheriting,
              editable,
            );
          });

          it(`renders GlFormTextarea, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
            expect(findGlFormTextarea().exists()).toBe(true);
            expect('readonly' in findGlFormTextarea().find('textarea').attributes()).toBe(readonly);
          });

          it('does not render other types of input', () => {
            expect(findGlFormCheckbox().exists()).toBe(false);
            expect(findGlFormSelect().exists()).toBe(false);
            expect(findGlFormInput().exists()).toBe(false);
          });
        });

        describe('type is password', () => {
          beforeEach(() => {
            createComponent(
              {
                type: 'password',
              },
              isInheriting,
              editable,
            );
          });

          it(`renders GlFormInput, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
            expect(findGlFormInput().exists()).toBe(true);
            expect(findGlFormInput().attributes('type')).toBe('password');
            expect('readonly' in findGlFormInput().attributes()).toBe(readonly);
          });

          it('does not render other types of input', () => {
            expect(findGlFormCheckbox().exists()).toBe(false);
            expect(findGlFormSelect().exists()).toBe(false);
            expect(findGlFormTextarea().exists()).toBe(false);
          });
        });

        describe('type is text', () => {
          beforeEach(() => {
            createComponent(
              {
                type: 'text',
                required: true,
              },
              isInheriting,
              editable,
            );
          });

          it(`renders GlFormInput, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
            expect(findGlFormInput().exists()).toBe(true);
            expect(findGlFormInput().attributes()).toMatchObject({
              type: 'text',
              id: 'service-project_url',
              name: 'service[project_url]',
              placeholder: mockField.placeholder,
              required: expect.any(String),
            });
            expect('readonly' in findGlFormInput().attributes()).toBe(readonly);
          });

          it('does not render other types of input', () => {
            expect(findGlFormCheckbox().exists()).toBe(false);
            expect(findGlFormSelect().exists()).toBe(false);
            expect(findGlFormTextarea().exists()).toBe(false);
          });
        });
      },
    );

    describe('help text', () => {
      it('renders description with help text', () => {
        createComponent();

        expect(findGlFormGroup().find('small').text()).toBe(mockField.help);
      });

      describe('when type is checkbox', () => {
        it('renders description with help text', () => {
          createComponent({
            type: 'checkbox',
          });

          expect(findGlFormGroup().find('small').exists()).toBe(false);
          expect(findGlFormCheckbox().text()).toContain(mockField.help);
        });
      });

      it('renders description with help text as HTML', () => {
        const helpHTML = 'The <strong>URL</strong> of the project';

        createComponent({
          help: helpHTML,
        });

        expect(findGlFormGroup().find('small').html()).toContain(helpHTML);
      });

      it('applies custom classes to the form group field', () => {
        const fieldClass = 'class1 class2';

        createComponent({
          fieldClass,
        });

        expect(findGlFormGroup().attributes('class')).toContain(fieldClass);
      });

      it('strips unsafe HTML from the help text', () => {
        const helpHTML =
          '[<code>1</code> <iframe>2</iframe> <a href="javascript:alert(document.cookie)">3</a> <a href="foo" target="_blank">4</a>]';

        createComponent({
          help: helpHTML,
        });

        expect(findGlFormGroup().find('small').html()).toContain(
          '[<code>1</code>  <a>3</a> <a href="foo" target="_blank" rel="noopener noreferrer">4</a>',
        );
      });
    });

    it('emits update event when model is changed', async () => {
      createComponent();
      findGlFormInput().vm.$emit('input', 'example');

      await nextTick();

      expect(wrapper.emitted('update')).toEqual([['example']]);
    });

    describe('label text', () => {
      it('renders label with title', () => {
        createComponent();

        expect(findGlFormGroup().find('label').text()).toBe(mockField.title);
      });
    });

    describe('with label description', () => {
      it('renders label description', () => {
        createComponent({
          labelDescription: 'This is a description',
        });

        expect(findGlFormGroup().props('labelDescription')).toBe('This is a description');
      });
    });

    describe('password field validations', () => {
      describe('without value', () => {
        it('requires validation', () => {
          createComponent({
            type: 'password',
            required: true,
            value: null,
            isValidated: true,
          });

          expect(findGlFormGroup().classes('is-invalid')).toBe(true);
          expect(findGlFormInput().classes('is-invalid')).toBe(true);
        });
      });

      describe('with value', () => {
        it('does not require validation', () => {
          createComponent({
            type: 'password',
            required: true,
            value: 'test value',
            isValidated: true,
          });

          expect(findGlFormGroup().classes('is-valid')).toBe(true);
          expect(findGlFormInput().classes('is-valid')).toBe(true);
        });
      });
    });
  });
});
