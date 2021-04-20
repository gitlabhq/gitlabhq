/**
 * Return the union of the given components' props options. Required props take
 * precendence over non-required props of the same name.
 *
 * This makes two assumptions:
 *  - All given components define their props in verbose object format.
 *  - The components all agree on the `type` of a common prop.
 *
 * @param {object[]} components The components to derive the union from.
 * @returns {object} The union of the props of the given components.
 */
export const propsUnion = (components) =>
  components.reduce((acc, component) => {
    Object.entries(component.props ?? {}).forEach(([propName, propOptions]) => {
      if (process.env.NODE_ENV !== 'production') {
        if (typeof propOptions !== 'object' || !('type' in propOptions)) {
          throw new Error(
            `Cannot create props union: expected verbose prop options for prop "${propName}"`,
          );
        }

        if (propName in acc && acc[propName]?.type !== propOptions?.type) {
          throw new Error(
            `Cannot create props union: incompatible prop types for prop "${propName}"`,
          );
        }
      }

      if (!(propName in acc) || propOptions.required) {
        acc[propName] = propOptions;
      }
    });

    return acc;
  }, {});
