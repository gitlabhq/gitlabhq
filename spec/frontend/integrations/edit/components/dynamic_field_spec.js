import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import DynamicField from '~/integrations/edit/components/dynamic_field.vue';

describe('DynamicField', () => {
  let wrapper;

  const defaultProps = {
    help: 'The URL of the project',
    name: 'project_url',
    placeholder: 'https://jira.example.com',
    title: 'Project URL',
    type: 'text',
    value: '1',
  };

  const createComponent = (props, isInheriting = false) => {
    wrapper = mount(DynamicField, {
      propsData: { ...defaultProps, ...props },
      computed: {
        isInheriting: () => isInheriting,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findGlFormSelect = () => wrapper.findComponent(GlFormSelect);
  const findGlFormTextarea = () => wrapper.findComponent(GlFormTextarea);

  describe('template', () => {
    describe.each([
      [true, 'disabled', 'readonly'],
      [false, undefined, undefined],
    ])('dynamic field, when isInheriting = `%p`', (isInheriting, disabled, readonly) => {
      describe('type is checkbox', () => {
        beforeEach(() => {
          createComponent(
            {
              type: 'checkbox',
            },
            isInheriting,
          );
        });

        it(`renders GlFormCheckbox, which ${isInheriting ? 'is' : 'is not'} disabled`, () => {
          expect(findGlFormCheckbox().exists()).toBe(true);
          expect(findGlFormCheckbox().find('[type=checkbox]').attributes('disabled')).toBe(
            disabled,
          );
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
          );
        });

        it(`renders GlFormTextarea, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
          expect(findGlFormTextarea().exists()).toBe(true);
          expect(findGlFormTextarea().find('textarea').attributes('readonly')).toBe(readonly);
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
          );
        });

        it(`renders GlFormInput, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
          expect(findGlFormInput().exists()).toBe(true);
          expect(findGlFormInput().attributes('type')).toBe('password');
          expect(findGlFormInput().attributes('readonly')).toBe(readonly);
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
          );
        });

        it(`renders GlFormInput, which ${isInheriting ? 'is' : 'is not'} readonly`, () => {
          expect(findGlFormInput().exists()).toBe(true);
          expect(findGlFormInput().attributes()).toMatchObject({
            type: 'text',
            id: 'service_project_url',
            name: 'service[project_url]',
            placeholder: defaultProps.placeholder,
            required: 'required',
          });
          expect(findGlFormInput().attributes('readonly')).toBe(readonly);
        });

        it('does not render other types of input', () => {
          expect(findGlFormCheckbox().exists()).toBe(false);
          expect(findGlFormSelect().exists()).toBe(false);
          expect(findGlFormTextarea().exists()).toBe(false);
        });
      });
    });

    describe('help text', () => {
      it('renders description with help text', () => {
        createComponent();

        expect(findGlFormGroup().find('small').text()).toBe(defaultProps.help);
      });

      it('renders description with help text as HTML', () => {
        const helpHTML = 'The <strong>URL</strong> of the project';

        createComponent({
          help: helpHTML,
        });

        expect(findGlFormGroup().find('small').html()).toContain(helpHTML);
      });
    });

    describe('label text', () => {
      it('renders label with title', () => {
        createComponent();

        expect(findGlFormGroup().find('label').text()).toBe(defaultProps.title);
      });
    });

    describe('validations', () => {
      describe('password field', () => {
        beforeEach(() => {
          createComponent({
            type: 'password',
            required: true,
            value: null,
          });

          wrapper.vm.validated = true;
        });

        describe('without value', () => {
          it('requires validation', () => {
            expect(wrapper.vm.valid).toBe(false);
            expect(findGlFormGroup().classes('is-invalid')).toBe(true);
            expect(findGlFormInput().classes('is-invalid')).toBe(true);
          });
        });

        describe('with value', () => {
          beforeEach(() => {
            wrapper.setProps({ value: 'true' });
          });

          it('does not require validation', () => {
            expect(wrapper.vm.valid).toBe(true);
            expect(findGlFormGroup().classes('is-valid')).toBe(true);
            expect(findGlFormInput().classes('is-valid')).toBe(true);
          });
        });
      });
    });
  });
});
