import _ from 'underscore';
import axios from '../lib/utils/axios_utils';
import { s__ } from '../locale';
import Flash from '../flash';
import { convertPermissionToBoolean } from '../lib/utils/common_utils';
import statusCodes from '../lib/utils/http_status';
import VariableList from './ci_variable_list';

function generateErrorBoxContent(errors) {
  const errorList = [].concat(errors).map(errorString => `
    <li>
      ${_.escape(errorString)}
    </li>
  `);

  return `
    <p>
      ${s__('CiVariable|Validation failed')}
    </p>
    <ul>
      ${errorList.join('')}
    </ul>
  `;
}

// Used for the variable list on CI/CD projects/groups settings page
export default class AjaxVariableList {
  constructor({
    container,
    saveButton,
    errorBox,
    formField = 'variables',
    saveEndpoint,
  }) {
    this.container = container;
    this.saveButton = saveButton;
    this.errorBox = errorBox;
    this.saveEndpoint = saveEndpoint;

    this.variableList = new VariableList({
      container: this.container,
      formField,
    });

    this.bindEvents();
    this.variableList.init();
  }

  bindEvents() {
    this.saveButton.addEventListener('click', this.onSaveClicked.bind(this));
  }

  onSaveClicked() {
    const loadingIcon = this.saveButton.querySelector('.js-secret-variables-save-loading-icon');
    loadingIcon.classList.toggle('hide', false);
    this.errorBox.classList.toggle('hide', true);
    // We use this to prevent a user from changing a key before we have a chance
    // to match it up in `updateRowsWithPersistedVariables`
    this.variableList.toggleEnableRow(false);

    return axios.patch(this.saveEndpoint, {
      variables_attributes: this.variableList.getAllData(),
    }, {
      // We want to be able to process the `res.data` from a 400 error response
      // and print the validation messages such as duplicate variable keys
      validateStatus: status => (
          status >= statusCodes.OK &&
          status < statusCodes.MULTIPLE_CHOICES
        ) ||
        status === statusCodes.BAD_REQUEST,
    })
      .then((res) => {
        loadingIcon.classList.toggle('hide', true);
        this.variableList.toggleEnableRow(true);

        if (res.status === statusCodes.OK && res.data) {
          this.updateRowsWithPersistedVariables(res.data.variables);
          this.variableList.hideValues();
        } else if (res.status === statusCodes.BAD_REQUEST) {
          // Validation failed
          this.errorBox.innerHTML = generateErrorBoxContent(res.data);
          this.errorBox.classList.toggle('hide', false);
        }
      })
      .catch(() => {
        loadingIcon.classList.toggle('hide', true);
        this.variableList.toggleEnableRow(true);
        Flash(s__('CiVariable|Error occured while saving variables'));
      });
  }

  updateRowsWithPersistedVariables(persistedVariables = []) {
    const persistedVariableMap = [].concat(persistedVariables).reduce((variableMap, variable) => ({
      ...variableMap,
      [variable.key]: variable,
    }), {});

    this.container.querySelectorAll('.js-row').forEach((row) => {
      // If we submitted a row that was destroyed, remove it so we don't try
      // to destroy it again which would cause a BE error
      const destroyInput = row.querySelector('.js-ci-variable-input-destroy');
      if (convertPermissionToBoolean(destroyInput.value)) {
        row.remove();
      // Update the ID input so any future edits and `_destroy` will apply on the BE
      } else {
        const key = row.querySelector('.js-ci-variable-input-key').value;
        const persistedVariable = persistedVariableMap[key];

        if (persistedVariable) {
          // eslint-disable-next-line no-param-reassign
          row.querySelector('.js-ci-variable-input-id').value = persistedVariable.id;
          row.setAttribute('data-is-persisted', 'true');
        }
      }
    });
  }
}
