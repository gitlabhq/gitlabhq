import { cloneDeep } from 'lodash';
import { displayText, types } from '../constants';

const variableTypeHandler = type =>
  type === displayText.variableText ? types.variableType : types.fileType;

export const prepareDataForDisplay = variables => {
  const variablesToDisplay = [];
  variables.forEach(variable => {
    const variableCopy = variable;
    if (variableCopy.variable_type === types.variableType) {
      variableCopy.variable_type = displayText.variableText;
    } else {
      variableCopy.variable_type = displayText.fileText;
    }
    variableCopy.secret_value = variableCopy.value;

    if (variableCopy.environment_scope === types.allEnvironmentsType) {
      variableCopy.environment_scope = displayText.allEnvironmentsText;
    }
    variableCopy.protected_variable = variableCopy.protected;
    variablesToDisplay.push(variableCopy);
  });
  return variablesToDisplay;
};

export const prepareDataForApi = (variable, destroy = false) => {
  const variableCopy = cloneDeep(variable);
  variableCopy.protected = variableCopy.protected_variable.toString();
  delete variableCopy.protected_variable;
  variableCopy.masked = variableCopy.masked.toString();
  variableCopy.variable_type = variableTypeHandler(variableCopy.variable_type);
  if (variableCopy.environment_scope === displayText.allEnvironmentsText) {
    variableCopy.environment_scope = types.allEnvironmentsType;
  }

  if (destroy) {
    // eslint-disable-next-line
    variableCopy._destroy = destroy;
  }

  return variableCopy;
};

export const prepareEnvironments = environments => environments.map(e => e.name);
