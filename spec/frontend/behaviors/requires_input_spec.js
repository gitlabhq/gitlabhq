import $ from 'jquery';
import htmlNewBranch from 'test_fixtures/branches/new_branch.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import '~/behaviors/requires_input';

describe('requiresInput', () => {
  let submitButton;

  beforeEach(() => {
    setHTMLFixture(htmlNewBranch);
    submitButton = $('button[type="submit"]');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('disables submit when any field is required', () => {
    $('.js-requires-input').requiresInput();

    expect(submitButton).toBeDisabled();
  });

  it('enables submit when no field is required', () => {
    $('*[required=required]').prop('required', false);
    $('.js-requires-input').requiresInput();

    expect(submitButton).not.toBeDisabled();
  });

  it('enables submit when all required fields are pre-filled', () => {
    $('*[required=required]').remove();
    $('.js-requires-input').requiresInput();

    expect($('.submit')).not.toBeDisabled();
  });

  it('enables submit when all required fields receive input', () => {
    $('.js-requires-input').requiresInput();
    $('#required1').val('input1').change();

    expect(submitButton).toBeDisabled();

    $('#optional1').val('input1').change();

    expect(submitButton).toBeDisabled();

    $('#required2').val('input2').change();
    $('#required3').val('input3').change();
    $('#required4').val('input4').change();
    $('#required5').val('1').change();

    expect($('.submit')).not.toBeDisabled();
  });
});
