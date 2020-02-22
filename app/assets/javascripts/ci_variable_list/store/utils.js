import { __ } from '~/locale';
import { cloneDeep } from 'lodash';

const variableType = 'env_var';
const fileType = 'file';

const variableTypeHandler = type => (type === 'Variable' ? variableType : fileType);

export const prepareDataForDisplay = variables => {
  const variablesToDisplay = [];
  variables.forEach(variable => {
    const variableCopy = variable;
    if (variableCopy.variable_type === variableType) {
      variableCopy.variable_type = __('Variable');
    } else {
      variableCopy.variable_type = __('File');
    }

    if (variableCopy.environment_scope === '*') {
      variableCopy.environment_scope = __('All environments');
    }
    variablesToDisplay.push(variableCopy);
  });
  return variablesToDisplay;
};

export const prepareDataForApi = (variable, destroy = false) => {
  const variableCopy = cloneDeep(variable);
  variableCopy.protected = variableCopy.protected.toString();
  variableCopy.masked = variableCopy.masked.toString();
  variableCopy.variable_type = variableTypeHandler(variableCopy.variable_type);

  if (variableCopy.environment_scope === __('All environments')) {
    variableCopy.environment_scope = __('*');
  }

  if (destroy) {
    // eslint-disable-next-line
    variableCopy._destroy = destroy;
  }

  return variableCopy;
};

export const prepareEnvironments = environments => environments.map(e => e.name);
