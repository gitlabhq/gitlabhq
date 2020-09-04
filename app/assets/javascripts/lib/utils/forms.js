export const serializeFormEntries = entries =>
  entries.reduce((acc, { name, value }) => Object.assign(acc, { [name]: value }), {});

export const serializeForm = form => {
  const fdata = new FormData(form);
  const entries = Array.from(fdata.keys()).map(key => {
    let val = fdata.getAll(key);
    // Microsoft Edge has a bug in FormData.getAll() that returns an undefined
    // value for each form element that does not match the given key:
    // https://github.com/jimmywarting/FormData/issues/80
    val = val.filter(n => n);
    return { name: key, value: val.length === 1 ? val[0] : val };
  });

  return serializeFormEntries(entries);
};

/**
 * Check if the value provided is empty or not
 *
 * It is being used to check if a form input
 * value has been set or not
 *
 * @param {String, Number, Array} - Any form value
 * @returns {Boolean} - returns false if a value is set
 *
 * @example
 * returns true for '', [], null, undefined
 */
export const isEmptyValue = value => value == null || value.length === 0;

/**
 * A form object serializer
 *
 * @param {Object} - Form Object
 * @returns {Object} - Serialized Form Object
 *
 * @example
 * Input
 * {"project": {"value": "hello", "state": false}, "username": {"value": "john"}}
 *
 * Returns
 * {"project": "hello", "username": "john"}
 */
export const serializeFormObject = form =>
  Object.fromEntries(
    Object.entries(form).reduce((acc, [name, { value }]) => {
      if (!isEmptyValue(value)) {
        acc.push([name, value]);
      }
      return acc;
    }, []),
  );
