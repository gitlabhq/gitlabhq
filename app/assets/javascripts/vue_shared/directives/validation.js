import { __ } from '~/locale';
import { getInstanceFromDirective } from '~/lib/utils/vue3compat/get_instance_from_directive';

/**
 * Validation messages will take priority based on the property order.
 *
 * For example:
 * { valueMissing: {...}, urlTypeMismatch: {...} }
 *
 * `valueMissing` will be displayed the user has entered a value
 *  after that, if the input is not a valid URL then `urlTypeMismatch` will show
 */
const defaultFeedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
    message: __('Please fill out this field.'),
  },
  urlTypeMismatch: {
    isInvalid: (el) => el.type === 'url' && el.validity?.typeMismatch,
    message: __('Please enter a valid URL format, ex: http://www.example.com/home'),
  },
};

const getFeedbackForElement = (feedbackMap, el) => {
  const field = Object.values(feedbackMap).find((f) => f.isInvalid(el));
  let elMessage = null;
  if (field) {
    elMessage = el.getAttribute('validation-message');
  }

  return field?.message || elMessage || el.validationMessage;
};

const focusFirstInvalidInput = (e) => {
  const { target: formEl } = e;
  const invalidInput = formEl.querySelector('input:invalid');

  if (invalidInput) {
    invalidInput.focus();
  }
};

const getInputElement = (el) => {
  return el.querySelector('input') || el;
};

const isEveryFieldValid = (form) => Object.values(form.fields).every(({ state }) => state === true);

const createValidator =
  (feedbackMap) =>
  ({ el, form, reportInvalidInput = false }) => {
    const { name } = el;

    if (!name) {
      if (process.env.NODE_ENV === 'development') {
        // eslint-disable-next-line no-console
        console.warn(
          '[gitlab] the validation directive requires the given input to have "name" attribute',
        );
      }
      return;
    }

    const formField = form.fields[name];
    const isValid = el.checkValidity();

    // This makes sure we always report valid fields - this can be useful for cases where the consuming
    // component's logic depends on certain fields being in a valid state.
    // Invalid input, on the other hand, should only be reported once we want to display feedback to the user.
    // (eg.: After a field has been touched and moved away from, a submit-button has been clicked, ...)
    formField.state = reportInvalidInput ? isValid : isValid || null;
    formField.feedback = reportInvalidInput ? getFeedbackForElement(feedbackMap, el) : '';

    // eslint-disable-next-line no-param-reassign
    form.state = isEveryFieldValid(form);
  };

/**
 * Takes an object that allows to add or change custom feedback messages.
 * See possibilities here: https://developer.mozilla.org/en-US/docs/Web/API/ValidityState
 *
 * The passed in object will be merged with the built-in feedback
 * so it is possible to override a built-in message.
 *
 * @example
 * validate({
 *   tooLong: {
 *     isInvalid: el => el.validity.tooLong === true,
 *     message: 'Your custom feedback'
 *   }
 * })
 *
 * @example
 *   validate({
 *     valueMissing: {
 *       message: 'Your custom feedback'
 *     }
 *   })
 *
 * @param {Object<string, { message: string, isValid: ?function}>} customFeedbackMap
 * @returns {{ inserted: function, update: function }} validateDirective
 */
export default function initValidation(customFeedbackMap = {}) {
  const feedbackMap = { ...defaultFeedbackMap, ...customFeedbackMap };
  const elDataMap = new WeakMap();

  return {
    inserted(element, binding, vnode) {
      const { arg: showGlobalValidation } = binding;
      const el = getInputElement(element);
      const { form: formEl } = el;
      const instance = getInstanceFromDirective({ binding, vnode });

      const validate = createValidator(feedbackMap);
      const elData = { validate, isTouched: false, isBlurred: false };

      elDataMap.set(el, elData);

      el.addEventListener('input', function markAsTouched() {
        elData.isTouched = true;
        // once the element has been marked as touched we can stop listening on the 'input' event
        el.removeEventListener('input', markAsTouched);
      });

      el.addEventListener('blur', function markAsBlurred({ target }) {
        if (elData.isTouched) {
          elData.isBlurred = true;
          validate({ el: target, form: instance.form, reportInvalidInput: true });
          // this event handler can be removed, since the live-feedback in `update` takes over
          el.removeEventListener('blur', markAsBlurred);
        }
      });

      if (formEl) {
        formEl.addEventListener('submit', focusFirstInvalidInput);
      }

      validate({ el, form: instance.form, reportInvalidInput: showGlobalValidation });
    },
    update(element, binding, vnode) {
      const el = getInputElement(element);
      const { arg: showGlobalValidation } = binding;
      const { validate, isTouched, isBlurred } = elDataMap.get(el);
      const showValidationFeedback = showGlobalValidation || (isTouched && isBlurred);

      const instance = getInstanceFromDirective({ binding, vnode });
      validate({ el, form: instance.form, reportInvalidInput: showValidationFeedback });
    },
  };
}

/**
 * This is a helper that initialize the form fields structure to be used in initForm
 * @param {*} fieldValues
 * @returns formObject
 */
export const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

/**
 * This is a helper that initialize the form structure that is compliant to be used with the validation directive
 *
 * @example
 * const form initForm = initForm({
 *   fields: {
 *     name: {
 *       value: 'lorem'
 *     },
 *     description: {
 *       value: 'ipsum',
 *       required: false,
 *       skipValidation: true
 *     }
 *   }
 * })
 *
 * @example
 * const form initForm = initForm({
 *   state: true,   // to override
 *   foo: {         // something custom
 *     bar: 'lorem'
 *   },
 *   fields: {...}
 * })
 *
 * @param {*} formObject
 * @returns form
 */
export const initForm = ({ fields = {}, ...rest } = {}) => {
  const initFields = Object.fromEntries(
    Object.entries(fields).map(([fieldName, fieldValues]) => {
      return [fieldName, initFormField(fieldValues)];
    }),
  );

  return {
    state: false,
    showValidation: false,
    ...rest,
    fields: initFields,
  };
};
