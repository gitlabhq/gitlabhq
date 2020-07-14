import { mount } from '@vue/test-utils';
import DynamicField from '~/integrations/edit/components/dynamic_field.vue';
import { GlFormGroup, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormTextarea } from '@gitlab/ui';

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

  const createComponent = props => {
    wrapper = mount(DynamicField, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlFormGroup = () => wrapper.find(GlFormGroup);
  const findGlFormCheckbox = () => wrapper.find(GlFormCheckbox);
  const findGlFormInput = () => wrapper.find(GlFormInput);
  const findGlFormSelect = () => wrapper.find(GlFormSelect);
  const findGlFormTextarea = () => wrapper.find(GlFormTextarea);

  describe('template', () => {
    describe('dynamic field', () => {
      describe('type is checkbox', () => {
        beforeEach(() => {
          createComponent({
            type: 'checkbox',
          });
        });

        it('renders GlFormCheckbox', () => {
          expect(findGlFormCheckbox().exists()).toBe(true);
        });

        it('does not render other types of input', () => {
          expect(findGlFormSelect().exists()).toBe(false);
          expect(findGlFormTextarea().exists()).toBe(false);
          expect(findGlFormInput().exists()).toBe(false);
        });
      });

      describe('type is select', () => {
        beforeEach(() => {
          createComponent({
            type: 'select',
            choices: [['all', 'All details'], ['standard', 'Standard']],
          });
        });

        it('renders findGlFormSelect', () => {
          expect(findGlFormSelect().exists()).toBe(true);
          expect(findGlFormSelect().findAll('option')).toHaveLength(2);
        });

        it('does not render other types of input', () => {
          expect(findGlFormCheckbox().exists()).toBe(false);
          expect(findGlFormTextarea().exists()).toBe(false);
          expect(findGlFormInput().exists()).toBe(false);
        });
      });

      describe('type is textarea', () => {
        beforeEach(() => {
          createComponent({
            type: 'textarea',
          });
        });

        it('renders findGlFormTextarea', () => {
          expect(findGlFormTextarea().exists()).toBe(true);
        });

        it('does not render other types of input', () => {
          expect(findGlFormCheckbox().exists()).toBe(false);
          expect(findGlFormSelect().exists()).toBe(false);
          expect(findGlFormInput().exists()).toBe(false);
        });
      });

      describe('type is password', () => {
        beforeEach(() => {
          createComponent({
            type: 'password',
          });
        });

        it('renders GlFormInput', () => {
          expect(findGlFormInput().exists()).toBe(true);
          expect(findGlFormInput().attributes('type')).toBe('password');
        });

        it('does not render other types of input', () => {
          expect(findGlFormCheckbox().exists()).toBe(false);
          expect(findGlFormSelect().exists()).toBe(false);
          expect(findGlFormTextarea().exists()).toBe(false);
        });
      });

      describe('type is text', () => {
        beforeEach(() => {
          createComponent({
            type: 'text',
            required: true,
          });
        });

        it('renders GlFormInput', () => {
          expect(findGlFormInput().exists()).toBe(true);
          expect(findGlFormInput().attributes()).toMatchObject({
            type: 'text',
            id: 'service_project_url',
            name: 'service[project_url]',
            placeholder: defaultProps.placeholder,
            required: 'required',
          });
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

        expect(
          findGlFormGroup()
            .find('small')
            .text(),
        ).toBe(defaultProps.help);
      });

      it('renders description with help text as HTML', () => {
        const helpHTML = 'The <strong>URL</strong> of the project';

        createComponent({
          help: helpHTML,
        });

        expect(
          findGlFormGroup()
            .find('small')
            .html(),
        ).toContain(helpHTML);
      });
    });

    describe('label text', () => {
      it('renders label with title', () => {
        createComponent();

        expect(
          findGlFormGroup()
            .find('label')
            .text(),
        ).toBe(defaultProps.title);
      });

      describe('for password field with some value (hidden by backend)', () => {
        it('renders label with new password title', () => {
          createComponent({
            type: 'password',
            value: 'true',
          });

          expect(
            findGlFormGroup()
              .find('label')
              .text(),
          ).toBe(`Enter new ${defaultProps.title}`);
        });
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
