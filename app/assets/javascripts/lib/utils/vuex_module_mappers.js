import { mapValues, isString } from 'lodash';
import { mapState, mapActions } from 'vuex';

export const REQUIRE_STRING_ERROR_MESSAGE =
  '`vuex_module_mappers` can only be used with an array of strings, or an object with string values. Consider using the regular `vuex` map helpers instead.';

const normalizeFieldsToObject = (fields) => {
  return Array.isArray(fields)
    ? fields.reduce((acc, key) => Object.assign(acc, { [key]: key }), {})
    : fields;
};

const mapVuexModuleFields = ({ namespaceSelector, fields, vuexHelper, selector } = {}) => {
  // The `vuexHelper` needs an object which maps keys to field selector functions.
  const map = mapValues(normalizeFieldsToObject(fields), (value) => {
    if (!isString(value)) {
      throw new Error(REQUIRE_STRING_ERROR_MESSAGE);
    }

    // We need to use a good ol' function to capture the right "this".
    return function mappedFieldSelector(...args) {
      const namespace = namespaceSelector(this);

      return selector(namespace, value, ...args);
    };
  });

  return vuexHelper(map);
};

/**
 * Like `mapState`, but takes a function in the first param for selecting a namespace.
 *
 * ```
 * computed: {
 *   ...mapVuexModuleState(vm => vm.vuexModule, ['foo']),
 * }
 * ```
 *
 * @param {Function} namespaceSelector
 * @param {Array|Object} fields
 */
export const mapVuexModuleState = (namespaceSelector, fields) =>
  mapVuexModuleFields({
    namespaceSelector,
    fields,
    vuexHelper: mapState,
    selector: (namespace, value, state) => state[namespace][value],
  });

/**
 * Like `mapActions`, but takes a function in the first param for selecting a namespace.
 *
 * ```
 * methods: {
 *   ...mapVuexModuleActions(vm => vm.vuexModule, ['fetchFoos']),
 * }
 * ```
 *
 * @param {Function} namespaceSelector
 * @param {Array|Object} fields
 */
export const mapVuexModuleActions = (namespaceSelector, fields) =>
  mapVuexModuleFields({
    namespaceSelector,
    fields,
    vuexHelper: mapActions,
    selector: (namespace, value, dispatch, ...args) => dispatch(`${namespace}/${value}`, ...args),
  });

/**
 * Like `mapGetters`, but takes a function in the first param for selecting a namespace.
 *
 * ```
 * computed: {
 *   ...mapGetters(vm => vm.vuexModule, ['hasSearchInfo']),
 * }
 * ```
 *
 * @param {Function} namespaceSelector
 * @param {Array|Object} fields
 */
export const mapVuexModuleGetters = (namespaceSelector, fields) =>
  mapVuexModuleFields({
    namespaceSelector,
    fields,
    // `mapGetters` does not let us pass an object which maps to functions. Thankfully `mapState` does
    // and gives us access to the getters.
    vuexHelper: mapState,
    selector: (namespace, value, state, getters) => getters[`${namespace}/${value}`],
  });
