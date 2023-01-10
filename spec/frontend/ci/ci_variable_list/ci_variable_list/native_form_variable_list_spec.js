import $ from 'jquery';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setupNativeFormVariableList from '~/ci/ci_variable_list/native_form_variable_list';

describe('NativeFormVariableList', () => {
  let $wrapper;

  beforeEach(() => {
    loadHTMLFixture('pipeline_schedules/edit.html');
    $wrapper = $('.js-ci-variable-list-section');

    setupNativeFormVariableList({
      container: $wrapper,
      formField: 'schedule',
    });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('onFormSubmit', () => {
    it('should clear out the `name` attribute on the inputs for the last empty row on form submission (avoid BE validation)', () => {
      const $row = $wrapper.find('.js-row');

      expect($row.find('.js-ci-variable-input-key').attr('name')).toBe(
        'schedule[variables_attributes][][key]',
      );

      expect($row.find('.js-ci-variable-input-value').attr('name')).toBe(
        'schedule[variables_attributes][][secret_value]',
      );

      $wrapper.closest('form').trigger('trigger-submit');

      expect($row.find('.js-ci-variable-input-key').attr('name')).toBe('');
      expect($row.find('.js-ci-variable-input-value').attr('name')).toBe('');
    });
  });
});
