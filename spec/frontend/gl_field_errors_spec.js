import $ from 'jquery';
import htmlGlFieldErrors from 'test_fixtures_static/gl_field_errors.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import GlFieldErrors from '~/gl_field_errors';

describe('GL Style Field Errors', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  beforeEach(() => {
    setHTMLFixture(htmlGlFieldErrors);
    const $form = $('form.gl-show-field-errors');

    testContext.$form = $form;
    testContext.fieldErrors = new GlFieldErrors($form);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should select the correct input elements', () => {
    expect(testContext.$form).toBeDefined();
    expect(testContext.$form.length).toBe(1);
    expect(testContext.fieldErrors).toBeDefined();
    const { inputs } = testContext.fieldErrors.state;

    expect(inputs.length).toBe(6);
  });

  it('should ignore elements with custom error handling', () => {
    const customErrorFlag = 'gl-field-error-ignore';
    const customErrorElem = $(`.${customErrorFlag}`);

    expect(customErrorElem.length).toBe(1);

    const customErrors = testContext.fieldErrors.state.inputs.filter((input) => {
      return input.inputElement.hasClass(customErrorFlag);
    });

    expect(customErrors.length).toBe(0);
  });

  it('should not show any errors before submit attempt', () => {
    testContext.$form.find('.email').val('not-a-valid-email').keyup();
    testContext.$form.find('.text-required').val('').keyup();
    testContext.$form.find('.alphanumberic').val('?---*').keyup();

    const errorsShown = testContext.$form.find('.gl-field-error-outline');

    expect(errorsShown.length).toBe(0);
  });

  it('should show errors when input valid is submitted', () => {
    testContext.$form.find('.email').val('not-a-valid-email').keyup();
    testContext.$form.find('.text-required').val('').keyup();
    testContext.$form.find('.alphanumberic').val('?---*').keyup();

    testContext.$form.submit();

    const errorsShown = testContext.$form.find('.gl-field-error-outline');

    expect(errorsShown.length).toBe(4);
  });

  it('should properly track validity state on input after invalid submission attempt', () => {
    testContext.$form.submit();

    const emailInputModel = testContext.fieldErrors.state.inputs[1];
    const fieldState = emailInputModel.state;
    const emailInputElement = emailInputModel.inputElement;

    // No input
    expect(emailInputElement).toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(true);
    expect(fieldState.valid).toBe(false);

    // Then invalid input
    emailInputElement.val('not-a-valid-email').keyup();

    expect(emailInputElement).toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(false);
    expect(fieldState.valid).toBe(false);

    // Then valid input
    emailInputElement.val('email@gitlab.com').keyup();

    expect(emailInputElement).not.toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(false);
    expect(fieldState.valid).toBe(true);

    // Then invalid input
    emailInputElement.val('not-a-valid-email').keyup();

    expect(emailInputElement).toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(false);
    expect(fieldState.valid).toBe(false);

    // Then empty input
    emailInputElement.val('').keyup();

    expect(emailInputElement).toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(true);
    expect(fieldState.valid).toBe(false);

    // Then valid input
    emailInputElement.val('email@gitlab.com').keyup();

    expect(emailInputElement).not.toHaveClass('gl-field-error-outline');
    expect(fieldState.empty).toBe(false);
    expect(fieldState.valid).toBe(true);
  });

  it('should properly infer error messages', () => {
    testContext.$form.submit();
    const trackedInputs = testContext.fieldErrors.state.inputs;
    const inputHasTitle = trackedInputs[1];
    const hasTitleErrorElem = inputHasTitle.inputElement.siblings('.gl-field-error');
    const inputNoTitle = trackedInputs[2];
    const noTitleErrorElem = inputNoTitle.inputElement.siblings('.gl-field-error');

    expect(noTitleErrorElem.text()).toBe('This field is required.');
    expect(hasTitleErrorElem.text()).toBe('Please provide a valid email address.');
  });

  it('sanitizes error messages before appending them to DOM', () => {
    testContext.$form.submit();

    const trackedInputs = testContext.fieldErrors.state.inputs;
    const xssInput = trackedInputs[5];

    const xssErrorElem = xssInput.inputElement.siblings('.gl-field-error');

    expect(xssErrorElem.html()).toBe('xss:');
  });
});
