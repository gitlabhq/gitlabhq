import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFormInput } from '@gitlab/ui';
import ChronicDurationInput from '~/admin/application_settings/runner_token_expiration/components/chronic_duration_input.vue';

const MOCK_VALUE = 2 * 3600 + 20 * 60;

describe('admin/application_settings/runner_token_expiration/components/chronic_duration_input', () => {
  let wrapper;
  let textElement;
  let textFormInput;
  let hiddenElement;

  afterEach(() => {
    textElement = null;
    hiddenElement = null;
  });

  const findComponents = () => {
    textElement = wrapper.findComponent(GlFormInput).element;
    hiddenElement = wrapper.find('input[type=hidden]').element;

    textFormInput = wrapper.findComponent(GlFormInput);
  };

  const createComponent = (props = {}) => {
    wrapper = mount(ChronicDurationInput, { propsData: props });
    findComponents();
  };

  describe('value', () => {
    it('has human-readable output with value', () => {
      createComponent({ value: MOCK_VALUE });

      expect(textElement.value).toBe('2 hrs 20 mins');
      expect(hiddenElement.value).toBe(MOCK_VALUE.toString());
    });

    it('has empty output with no value', () => {
      createComponent({ value: null });

      expect(textElement.value).toBe('');
      expect(hiddenElement.value).toBe('');
    });
  });

  describe('change', () => {
    const createAndDispatch = async (initialValue, humanReadableInput) => {
      createComponent({ value: initialValue });
      await nextTick();
      textFormInput.vm.$emit('input', humanReadableInput);
    };

    describe('when starting with no value and receiving human-readable input', () => {
      beforeEach(() => {
        createAndDispatch(null, '2hr20min');
      });

      it('updates hidden field', () => {
        expect(textElement.value).toBe('2hr20min');
        expect(hiddenElement.value).toBe(MOCK_VALUE.toString());
      });

      it('emits change event', () => {
        expect(wrapper.emitted('change')).toEqual([[MOCK_VALUE]]);
      });
    });

    describe('when starting with a value and receiving empty input', () => {
      beforeEach(() => {
        createAndDispatch(MOCK_VALUE, '');
      });

      it('updates hidden field', () => {
        expect(textElement.value).toBe('');
        expect(hiddenElement.value).toBe('');
      });

      it('emits change event', () => {
        expect(wrapper.emitted('change')).toEqual([[null]]);
      });
    });

    describe('when starting with a value and receiving invalid input', () => {
      beforeEach(() => {
        createAndDispatch(MOCK_VALUE, 'gobbledygook');
      });

      it('does not update hidden field', () => {
        expect(textElement.value).toBe('gobbledygook');
        expect(hiddenElement.value).toBe(MOCK_VALUE.toString());
      });

      it('does not emit change event', () => {
        expect(wrapper.emitted('change')).toBeUndefined();
      });
    });
  });

  describe('valid', () => {
    describe('initial value', () => {
      beforeEach(() => {
        createComponent({ value: MOCK_VALUE });
      });

      it('emits valid with initial value', () => {
        expect(wrapper.emitted('valid')).toEqual([[{ valid: true, feedback: '' }]]);
        expect(textElement.validity.valid).toBe(true);
        expect(textElement.validity.customError).toBe(false);
        expect(textElement.validationMessage).toBe('');
        expect(hiddenElement.validity.valid).toBe(true);
        expect(hiddenElement.validity.customError).toBe(false);
        expect(hiddenElement.validationMessage).toBe('');
      });

      it('emits valid with user input', async () => {
        textFormInput.vm.$emit('input', '1m10s');
        await nextTick();

        expect(wrapper.emitted('valid')).toEqual([
          [{ valid: true, feedback: '' }],
          [{ valid: true, feedback: '' }],
        ]);
        expect(textElement.validity.valid).toBe(true);
        expect(textElement.validity.customError).toBe(false);
        expect(textElement.validationMessage).toBe('');
        expect(hiddenElement.validity.valid).toBe(true);
        expect(hiddenElement.validity.customError).toBe(false);
        expect(hiddenElement.validationMessage).toBe('');

        textFormInput.vm.$emit('input', '');
        await nextTick();

        expect(wrapper.emitted('valid')).toEqual([
          [{ valid: true, feedback: '' }],
          [{ valid: true, feedback: '' }],
          [{ valid: null, feedback: '' }],
        ]);
        expect(textElement.validity.valid).toBe(true);
        expect(textElement.validity.customError).toBe(false);
        expect(textElement.validationMessage).toBe('');
        expect(hiddenElement.validity.valid).toBe(true);
        expect(hiddenElement.validity.customError).toBe(false);
        expect(hiddenElement.validationMessage).toBe('');
      });

      it('emits invalid with user input', async () => {
        textFormInput.vm.$emit('input', 'gobbledygook');
        await nextTick();

        expect(wrapper.emitted('valid')).toEqual([
          [{ valid: true, feedback: '' }],
          [{ valid: false, feedback: ChronicDurationInput.i18n.INVALID_INPUT_FEEDBACK }],
        ]);
        expect(textElement.validity.valid).toBe(false);
        expect(textElement.validity.customError).toBe(true);
        expect(textElement.validationMessage).toBe(
          ChronicDurationInput.i18n.INVALID_INPUT_FEEDBACK,
        );
        expect(hiddenElement.validity.valid).toBe(false);
        expect(hiddenElement.validity.customError).toBe(true);
        // Hidden elements do not have validationMessage
        expect(hiddenElement.validationMessage).toBe('');
      });
    });

    describe('no initial value', () => {
      beforeEach(() => {
        createComponent({ value: null });
      });

      it('emits valid with no initial value', () => {
        expect(wrapper.emitted('valid')).toEqual([[{ valid: null, feedback: '' }]]);
        expect(textElement.validity.valid).toBe(true);
        expect(textElement.validity.customError).toBe(false);
        expect(textElement.validationMessage).toBe('');
        expect(hiddenElement.validity.valid).toBe(true);
        expect(hiddenElement.validity.customError).toBe(false);
        expect(hiddenElement.validationMessage).toBe('');
      });

      it('emits valid with updated value', async () => {
        wrapper.setProps({ value: MOCK_VALUE });
        await nextTick();

        expect(wrapper.emitted('valid')).toEqual([
          [{ valid: null, feedback: '' }],
          [{ valid: true, feedback: '' }],
        ]);
        expect(textElement.validity.valid).toBe(true);
        expect(textElement.validity.customError).toBe(false);
        expect(textElement.validationMessage).toBe('');
        expect(hiddenElement.validity.valid).toBe(true);
        expect(hiddenElement.validity.customError).toBe(false);
        expect(hiddenElement.validationMessage).toBe('');
      });
    });

    describe('decimal input', () => {
      describe('when integerRequired is false', () => {
        beforeEach(() => {
          createComponent({ value: null, integerRequired: false });
        });

        it('emits valid when input is integer', async () => {
          textFormInput.vm.$emit('input', '2hr20min');
          await nextTick();

          expect(wrapper.emitted('change')).toEqual([[MOCK_VALUE]]);
          expect(wrapper.emitted('valid')).toEqual([
            [{ valid: null, feedback: '' }],
            [{ valid: true, feedback: '' }],
          ]);
          expect(textElement.validity.valid).toBe(true);
          expect(textElement.validity.customError).toBe(false);
          expect(textElement.validationMessage).toBe('');
          expect(hiddenElement.validity.valid).toBe(true);
          expect(hiddenElement.validity.customError).toBe(false);
          expect(hiddenElement.validationMessage).toBe('');
        });

        it('emits valid when input is decimal', async () => {
          textFormInput.vm.$emit('input', '1.5s');
          await nextTick();

          expect(wrapper.emitted('change')).toEqual([[1.5]]);
          expect(wrapper.emitted('valid')).toEqual([
            [{ valid: null, feedback: '' }],
            [{ valid: true, feedback: '' }],
          ]);
          expect(textElement.validity.valid).toBe(true);
          expect(textElement.validity.customError).toBe(false);
          expect(textElement.validationMessage).toBe('');
          expect(hiddenElement.validity.valid).toBe(true);
          expect(hiddenElement.validity.customError).toBe(false);
          expect(hiddenElement.validationMessage).toBe('');
        });
      });

      describe('when integerRequired is unspecified', () => {
        beforeEach(() => {
          createComponent({ value: null });
        });

        it('emits valid when input is integer', async () => {
          textFormInput.vm.$emit('input', '2hr20min');
          await nextTick();

          expect(wrapper.emitted('change')).toEqual([[MOCK_VALUE]]);
          expect(wrapper.emitted('valid')).toEqual([
            [{ valid: null, feedback: '' }],
            [{ valid: true, feedback: '' }],
          ]);
          expect(textElement.validity.valid).toBe(true);
          expect(textElement.validity.customError).toBe(false);
          expect(textElement.validationMessage).toBe('');
          expect(hiddenElement.validity.valid).toBe(true);
          expect(hiddenElement.validity.customError).toBe(false);
          expect(hiddenElement.validationMessage).toBe('');
        });

        it('emits invalid when input is decimal', async () => {
          textFormInput.vm.$emit('input', '1.5s');
          await nextTick();

          expect(wrapper.emitted('change')).toBeUndefined();
          expect(wrapper.emitted('valid')).toEqual([
            [{ valid: null, feedback: '' }],
            [
              {
                valid: false,
                feedback: ChronicDurationInput.i18n.INVALID_DECIMAL_FEEDBACK,
              },
            ],
          ]);
          expect(textElement.validity.valid).toBe(false);
          expect(textElement.validity.customError).toBe(true);
          expect(textElement.validationMessage).toBe(
            ChronicDurationInput.i18n.INVALID_DECIMAL_FEEDBACK,
          );
          expect(hiddenElement.validity.valid).toBe(false);
          expect(hiddenElement.validity.customError).toBe(true);
          // Hidden elements do not have validationMessage
          expect(hiddenElement.validationMessage).toBe('');
        });
      });
    });
  });

  describe('v-model', () => {
    beforeEach(() => {
      wrapper = mount({
        data() {
          return { value: 1 * 60 + 10 };
        },
        components: { ChronicDurationInput },
        template: '<div><chronic-duration-input v-model="value"/></div>',
      });
      findComponents();
    });

    describe('value', () => {
      it('passes initial prop via v-model', () => {
        expect(textElement.value).toBe('1 min 10 secs');
        expect(hiddenElement.value).toBe((1 * 60 + 10).toString());
      });

      it('passes updated prop via v-model', async () => {
        textFormInput.vm.$emit('input', '2hr20min');
        await nextTick();

        expect(textElement.value).toBe('2hr20min');
        expect(hiddenElement.value).toBe(MOCK_VALUE.toString());
      });
    });

    describe('change', () => {
      it('passes user input to parent via v-model', async () => {
        textFormInput.vm.$emit('input', '2hr20min');
        await nextTick();

        expect(wrapper.findComponent(ChronicDurationInput).props('value')).toBe(MOCK_VALUE);
        expect(textElement.value).toBe('2hr20min');
        expect(hiddenElement.value).toBe(MOCK_VALUE.toString());
      });
    });
  });

  describe('name', () => {
    beforeEach(() => {
      createComponent({ name: 'myInput' });
    });

    it('sets name of hidden field', () => {
      expect(hiddenElement.name).toBe('myInput');
    });

    it('does not set name of text field', () => {
      expect(textElement.name).toBe('');
    });
  });

  describe('form submission', () => {
    beforeEach(() => {
      wrapper = mount({
        template: `<form data-testid="myForm"><chronic-duration-input name="myInput" :value="${MOCK_VALUE}"/></form>`,
        components: {
          ChronicDurationInput,
        },
      });
      findComponents();
    });

    it('creates form data with initial value', () => {
      const formData = new FormData(wrapper.find('[data-testid=myForm]').element);
      const iter = formData.entries();

      expect(iter.next()).toEqual({
        value: ['myInput', MOCK_VALUE.toString()],
        done: false,
      });
      expect(iter.next()).toEqual({ value: undefined, done: true });
    });

    it('creates form data with user-specified value', async () => {
      textFormInput.vm.$emit('input', '1m10s');
      await nextTick();

      const formData = new FormData(wrapper.find('[data-testid=myForm]').element);
      const iter = formData.entries();

      expect(iter.next()).toEqual({
        value: ['myInput', (1 * 60 + 10).toString()],
        done: false,
      });
      expect(iter.next()).toEqual({ value: undefined, done: true });
    });
  });
});
