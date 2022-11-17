/**
 * Get query parameters used for users request from passed `options` parameter
 * @param {Object} options e.g. { currentUserId: 1, fooBar: 'baz' }
 * @param {Object} paramsMap e.g. { user_id: 'currentUserId', foo_bar: 'fooBar' }
 */
export const getAjaxUsersSelectParams = (options, paramsMap) => {
  return Object.keys(paramsMap).reduce((accumulator, paramKey) => {
    const optionKey = paramsMap[paramKey];
    accumulator[paramKey] = options[optionKey] || null;

    return accumulator;
  }, {});
};
