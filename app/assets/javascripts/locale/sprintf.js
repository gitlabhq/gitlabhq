import _ from 'underscore';

/**
  Very limited implementation of sprintf supporting only named parameters.

  @param input (translated) text with parameters (e.g. '%{num_users} users use us')
  @param parameters object mapping parameter names to values (e.g. { num_users: 5 })
  @param escapeParameters whether parameter values should be escaped (see http://underscorejs.org/#escape)
  @returns {String} the text with parameters replaces (e.g. '5 users use us')

  @see https://ruby-doc.org/core-2.3.3/Kernel.html#method-i-sprintf
  @see https://gitlab.com/gitlab-org/gitlab-ce/issues/37992
**/
export default (input, parameters, escapeParameters = true) => {
  let output = input;

  if (parameters) {
    Object.keys(parameters).forEach((parameterName) => {
      const parameterValue = parameters[parameterName];
      const escapedParameterValue = escapeParameters ? _.escape(parameterValue) : parameterValue;
      output = output.replace(new RegExp(`%{${parameterName}}`, 'g'), escapedParameterValue);
    });
  }

  return output;
};
