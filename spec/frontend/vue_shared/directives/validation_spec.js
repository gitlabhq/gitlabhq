import { shallowMount } from '@vue/test-utils';
import validation from '~/vue_shared/directives/validation';

describe('validation directive', () => {
  let wrapper;

  const createComponent = ({ inputAttributes, showValidation, template } = {}) => {
    const defaultInputAttributes = {
      type: 'text',
      required: true,
    };

    const defaultTemplate = `
      <form>
        <input v-validation:[showValidation] name="exampleField" v-bind="attributes" />
      </form>
    `;

    const component = {
      directives: {
        validation: validation(),
      },
      data() {
        return {
          attributes: inputAttributes || defaultInputAttributes,
          showValidation,
          form: {
            state: null,
            fields: {
              exampleField: {
                state: null,
                feedback: '',
              },
            },
          },
        };
      },
      template: template || defaultTemplate,
    };

    wrapper = shallowMount(component, { attachTo: document.body });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getFormData = () => wrapper.vm.form;
  const findForm = () => wrapper.find('form');
  const findInput = () => wrapper.find('input');

  const setValueAndTriggerValidation = (value) => {
    const input = findInput();
    input.setValue(value);
    input.trigger('blur');
  };

  describe.each([true, false])(
    'with fields untouched and "showValidation" set to "%s"',
    (showValidation) => {
      beforeEach(() => {
        createComponent({ showValidation });
      });

      it('sets the fields validity correctly', () => {
        expect(getFormData().fields.exampleField).toEqual({
          state: showValidation ? false : null,
          feedback: showValidation ? expect.any(String) : '',
        });
      });

      it('sets the form validity correctly', () => {
        expect(getFormData().state).toBe(false);
      });
    },
  );

  describe.each`
    inputAttributes                       | validValue          | invalidValue
    ${{ required: true }}                 | ${'foo'}            | ${''}
    ${{ type: 'url' }}                    | ${'http://foo.com'} | ${'foo'}
    ${{ type: 'number', min: 1, max: 5 }} | ${3}                | ${0}
    ${{ type: 'number', min: 1, max: 5 }} | ${3}                | ${6}
    ${{ pattern: 'foo|bar' }}             | ${'bar'}            | ${'quz'}
  `(
    'with input-attributes set to $inputAttributes',
    ({ inputAttributes, validValue, invalidValue }) => {
      beforeEach(() => {
        createComponent({ inputAttributes });
      });

      describe('with valid value', () => {
        beforeEach(() => {
          setValueAndTriggerValidation(validValue);
        });

        it('sets the field to be valid', () => {
          expect(getFormData().fields.exampleField).toEqual({
            state: true,
            feedback: '',
          });
        });

        it('sets the form to be valid', () => {
          expect(getFormData().state).toBe(true);
        });
      });

      describe('with invalid value', () => {
        beforeEach(() => {
          setValueAndTriggerValidation(invalidValue);
        });

        it('sets the field to be invalid', () => {
          expect(getFormData().fields.exampleField).toEqual({
            state: false,
            feedback: expect.any(String),
          });
          expect(getFormData().fields.exampleField.feedback.length).toBeGreaterThan(0);
        });

        it('sets the form to be invalid', () => {
          expect(getFormData().state).toBe(false);
        });

        it('sets focus on the first invalid input when the form is submitted', () => {
          findForm().trigger('submit');
          expect(findInput().element).toBe(document.activeElement);
        });
      });
    },
  );

  describe('with group elements', () => {
    const template = `
      <form>
        <div v-validation:[showValidation]>
          <input name="exampleField" v-bind="attributes" />
        </div>
      </form>
    `;
    beforeEach(() => {
      createComponent({
        template,
        inputAttributes: {
          required: true,
        },
      });
    });

    describe('with invalid value', () => {
      beforeEach(() => {
        setValueAndTriggerValidation('');
      });

      it('should set correct field state', () => {
        expect(getFormData().fields.exampleField).toEqual({
          state: false,
          feedback: expect.any(String),
        });
      });

      it('should set correct feedback', () => {
        expect(getFormData().fields.exampleField.feedback).toBe('Please fill out this field.');
      });
    });

    describe('with valid value', () => {
      beforeEach(() => {
        setValueAndTriggerValidation('hello');
      });

      it('set the correct state', () => {
        expect(getFormData().fields.exampleField).toEqual({
          state: true,
          feedback: '',
        });
      });
    });
  });
});
