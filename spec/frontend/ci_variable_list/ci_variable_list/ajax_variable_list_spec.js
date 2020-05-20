import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AjaxFormVariableList from '~/ci_variable_list/ajax_variable_list';

const VARIABLE_PATCH_ENDPOINT = 'http://test.host/frontend-fixtures/builds-project/-/variables';
const HIDE_CLASS = 'hide';

describe('AjaxFormVariableList', () => {
  preloadFixtures('projects/ci_cd_settings.html');
  preloadFixtures('projects/ci_cd_settings_with_variables.html');

  let container;
  let saveButton;
  let errorBox;

  let mock;
  let ajaxVariableList;

  beforeEach(() => {
    loadFixtures('projects/ci_cd_settings.html');
    container = document.querySelector('.js-ci-variable-list-section');

    mock = new MockAdapter(axios);

    const ajaxVariableListEl = document.querySelector('.js-ci-variable-list-section');
    saveButton = ajaxVariableListEl.querySelector('.js-ci-variables-save-button');
    errorBox = container.querySelector('.js-ci-variable-error-box');
    ajaxVariableList = new AjaxFormVariableList({
      container,
      formField: 'variables',
      saveButton,
      errorBox,
      saveEndpoint: container.dataset.saveEndpoint,
      maskableRegex: container.dataset.maskableRegex,
    });

    jest.spyOn(ajaxVariableList, 'updateRowsWithPersistedVariables');
    jest.spyOn(ajaxVariableList.variableList, 'toggleEnableRow');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('onSaveClicked', () => {
    it('shows loading spinner while waiting for the request', () => {
      const loadingIcon = saveButton.querySelector('.js-ci-variables-save-loading-icon');

      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(() => {
        expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(false);

        return [200, {}];
      });

      expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(true);

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(true);
      });
    });

    it('calls `updateRowsWithPersistedVariables` with the persisted variables', () => {
      const variablesResponse = [{ id: 1, key: 'foo', value: 'bar' }];
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200, {
        variables: variablesResponse,
      });

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(ajaxVariableList.updateRowsWithPersistedVariables).toHaveBeenCalledWith(
          variablesResponse,
        );
      });
    });

    it('hides any previous error box', () => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);
      });
    });

    it('disables remove buttons while waiting for the request', () => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(() => {
        expect(ajaxVariableList.variableList.toggleEnableRow).toHaveBeenCalledWith(false);

        return [200, {}];
      });

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(ajaxVariableList.variableList.toggleEnableRow).toHaveBeenCalledWith(true);
      });
    });

    it('hides secret values', () => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200, {});

      const row = container.querySelector('.js-row');
      const valueInput = row.querySelector('.js-ci-variable-input-value');
      const valuePlaceholder = row.querySelector('.js-secret-value-placeholder');

      valueInput.value = 'bar';
      $(valueInput).trigger('input');

      expect(valuePlaceholder.classList.contains(HIDE_CLASS)).toBe(true);
      expect(valueInput.classList.contains(HIDE_CLASS)).toBe(false);

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(valuePlaceholder.classList.contains(HIDE_CLASS)).toBe(false);
        expect(valueInput.classList.contains(HIDE_CLASS)).toBe(true);
      });
    });

    it('shows error box with validation errors', () => {
      const validationError = 'some validation error';
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(400, [validationError]);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(false);
        expect(errorBox.textContent.trim().replace(/\n+\s+/m, ' ')).toEqual(
          `Validation failed ${validationError}`,
        );
      });
    });

    it('shows flash message when request fails', () => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(500);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      return ajaxVariableList.onSaveClicked().then(() => {
        expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);
      });
    });
  });

  describe('updateRowsWithPersistedVariables', () => {
    beforeEach(() => {
      loadFixtures('projects/ci_cd_settings_with_variables.html');
      container = document.querySelector('.js-ci-variable-list-section');

      const ajaxVariableListEl = document.querySelector('.js-ci-variable-list-section');
      saveButton = ajaxVariableListEl.querySelector('.js-ci-variables-save-button');
      errorBox = container.querySelector('.js-ci-variable-error-box');
      ajaxVariableList = new AjaxFormVariableList({
        container,
        formField: 'variables',
        saveButton,
        errorBox,
        saveEndpoint: container.dataset.saveEndpoint,
      });
    });

    it('removes variable that was removed', () => {
      expect(container.querySelectorAll('.js-row').length).toBe(3);

      container.querySelector('.js-row-remove-button').click();

      expect(container.querySelectorAll('.js-row').length).toBe(3);

      ajaxVariableList.updateRowsWithPersistedVariables([]);

      expect(container.querySelectorAll('.js-row').length).toBe(2);
    });

    it('updates new variable row with persisted ID', () => {
      const row = container.querySelector('.js-row:last-child');
      const idInput = row.querySelector('.js-ci-variable-input-id');
      const keyInput = row.querySelector('.js-ci-variable-input-key');
      const valueInput = row.querySelector('.js-ci-variable-input-value');

      keyInput.value = 'foo';
      $(keyInput).trigger('input');
      valueInput.value = 'bar';
      $(valueInput).trigger('input');

      expect(idInput.value).toEqual('');

      ajaxVariableList.updateRowsWithPersistedVariables([
        {
          id: 3,
          key: 'foo',
          value: 'bar',
        },
      ]);

      expect(idInput.value).toEqual('3');
      expect(row.dataset.isPersisted).toEqual('true');
    });
  });

  describe('maskableRegex', () => {
    it('takes in the regex provided by the data attribute', () => {
      expect(container.dataset.maskableRegex).toBe('^[a-zA-Z0-9_+=/@:.-]{8,}$');
      expect(ajaxVariableList.maskableRegex).toBe(container.dataset.maskableRegex);
    });
  });
});
