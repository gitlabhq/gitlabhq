/**
 * Returns computed properties two way bound to vuex
 *
 * @param {(string[]|Object[])} list - list of string matching state keys or list objects
 * @param {string} list[].key - the key matching the key present in the vuex state
 * @param {string} list[].getter - the name of the getter, leave it empty to not use a getter
 * @param {string} list[].updateFn - the name of the action, leave it empty to use the default action
 * @param {string} defaultUpdateFn - the default function to dispatch
 * @param {string|function} root - the key of the state where to search for the keys described in list
 * @returns {Object} a dictionary with all the computed properties generated
 */
export const mapComputed = (list, defaultUpdateFn, root) => {
  const result = {};
  list.forEach((item) => {
    const [getter, key, updateFn] =
      typeof item === 'string'
        ? [false, item, defaultUpdateFn]
        : [item.getter, item.key, item.updateFn || defaultUpdateFn];
    result[key] = {
      get() {
        if (getter) {
          return this.$store.getters[getter];
        } else if (root) {
          if (typeof root === 'function') {
            return root(this.$store.state)[key];
          }

          return this.$store.state[root][key];
        }
        return this.$store.state[key];
      },
      set(value) {
        this.$store.dispatch(updateFn, { [key]: value });
      },
    };
  });
  return result;
};
