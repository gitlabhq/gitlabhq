import { escape } from 'lodash';

/**
 * Very limited implementation of sprintf supporting only named parameters.
 * @param {string} input - (translated) text with parameters (e.g. '%{num_users} users use us')
 * @param {Object.<string, string|number>} [parameters] - object mapping parameter names to values (e.g. { num_users: 5 })
 * @param {boolean} [escapeParameters=true] - whether parameter values should be escaped (see https://lodash.com/docs/4.17.15#escape)
 * @returns {string} the text with parameters replaces (e.g. '5 users use us')
 * @see https://ruby-doc.org/core-2.3.3/Kernel.html#method-i-sprintf
 * @see https://gitlab.com/gitlab-org/gitlab-foss/issues/37992
 */
export default function sprintf(input, parameters, escapeParameters = true) {
  return input.replace(/%%|%\{(\w+)\}/g, (match, key) => {
    // Escape %% to literal %
    if (match === '%%') return '%';

    if (parameters && key in parameters) {
      const value = parameters[key];
      return escapeParameters ? escape(value) : value;
    }

    return match;
  });
}
