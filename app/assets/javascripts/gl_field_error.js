import $ from 'jquery';

/**
 * This class overrides the browser's validation error bubbles, displaying custom
 * error messages for invalid fields instead. To begin validating any form, add the
 * class `gl-show-field-errors` to the form element, and ensure error messages are
 * declared in each inputs' `title` attribute. If no title is declared for an invalid
 * field the user attempts to submit, "This field is required." will be shown by default.
 *
 * Opt not to validate certain fields by adding the class `gl-field-error-ignore` to the input.
 *
 * Set a custom error anchor for error message to be injected after with the
 * class `gl-field-error-anchor`
 *
 * Examples:
 *
 * Basic:
 *
 * <form class='gl-show-field-errors'>
 *  <input type='text' name='username' title='Username is required.'/>
 * </form>
 *
 * Ignore specific inputs (e.g. UsernameValidator):
 *
 * <form class='gl-show-field-errors'>
 *   <div class="form-group>
 *     <input type='text' class='gl-field-errors-ignore' pattern='[a-zA-Z0-9-_]+'/>
 *   </div>
 *   <div class="form-group">
 *      <input type='text' name='username' title='Username is required.'/>
 *    </div>
 * </form>
 *
 * Custom Error Anchor (allows error message to be injected after specified element):
 *
 * <form class='gl-show-field-errors'>
 *  <div class="form-group gl-field-error-anchor">
 *    <input type='text' name='username' title='Username is required.'/>
 *    // Error message typically injected here
 *  </div>
 *  // Error message now injected here
 * </form>
 *
 */

/**
 * Regex Patterns in use:
 *
 * Only alphanumeric: : "[a-zA-Z0-9]+"
 * No special characters : "[a-zA-Z0-9-_]+",
 *
 */

const errorMessageClass = 'gl-field-error';
const inputErrorClass = 'gl-field-error-outline';
const errorAnchorSelector = '.gl-field-error-anchor';
const ignoreInputSelector = '.gl-field-error-ignore';

export default class GlFieldError {
  constructor({ input, formErrors }) {
    this.inputElement = $(input);
    this.inputDomElement = this.inputElement.get(0);
    this.form = formErrors;
    this.errorMessage = this.inputElement.attr('title') || 'This field is required.';
    this.fieldErrorElement = $(`<p class='${errorMessageClass} hide'>${this.errorMessage}</p>`);

    this.state = {
      valid: false,
      empty: true,
      submitted: false,
    };

    this.initFieldValidation();
  }

  initFieldValidation() {
    const customErrorAnchor = this.inputElement.parents(errorAnchorSelector);
    const errorAnchor = customErrorAnchor.length ? customErrorAnchor : this.inputElement;

    // hidden when injected into DOM
    errorAnchor.after(this.fieldErrorElement);
    this.inputElement.off('invalid').on('invalid', this.handleInvalidSubmit.bind(this));
    this.scopedSiblings = this.safelySelectSiblings();
  }

  safelySelectSiblings() {
    // Apply `ignoreSelector` in markup to siblings whose visibility should not be toggled
    const unignoredSiblings = this.inputElement.siblings(`p:not(${ignoreInputSelector})`);
    const parentContainer = this.inputElement.parent('.form-group');

    // Only select siblings when they're scoped within a form-group with one input
    const safelyScoped = parentContainer.length && parentContainer.find('input').length === 1;

    return safelyScoped ? unignoredSiblings : this.fieldErrorElement;
  }

  renderValidity() {
    this.renderClear();

    if (this.state.valid) {
      this.renderValid();
    } else if (this.state.empty) {
      this.renderEmpty();
    } else if (!this.state.valid) {
      this.renderInvalid();
    }
  }

  handleInvalidSubmit(event) {
    event.preventDefault();
    const currentValue = this.accessCurrentValue();
    this.state.valid = false;
    this.state.empty = currentValue === '';
    this.state.submitted = true;
    this.renderValidity();
    this.form.focusOnFirstInvalid.apply(this.form);

    // For UX, wait til after first invalid submission to check each keyup
    this.inputElement.off('keyup.fieldValidator')
      .on('keyup.fieldValidator', this.updateValidity.bind(this));
  }

  /* Get or set current input value */
  accessCurrentValue(newVal) {
    return newVal ? this.inputElement.val(newVal) : this.inputElement.val();
  }

  getInputValidity() {
    return this.inputDomElement.validity.valid;
  }

  updateValidity() {
    const inputVal = this.accessCurrentValue();
    this.state.empty = !inputVal.length;
    this.state.valid = this.getInputValidity();
    this.renderValidity();
  }

  renderValid() {
    return this.renderClear();
  }

  renderEmpty() {
    return this.renderInvalid();
  }

  renderInvalid() {
    this.inputElement.addClass(inputErrorClass);
    this.scopedSiblings.hide();
    return this.fieldErrorElement.show();
  }

  renderClear() {
    const inputVal = this.accessCurrentValue();
    if (!inputVal.split(' ').length) {
      const trimmedInput = inputVal.trim();
      this.accessCurrentValue(trimmedInput);
    }
    this.inputElement.removeClass(inputErrorClass);
    this.scopedSiblings.hide();
    this.fieldErrorElement.hide();
  }
}
