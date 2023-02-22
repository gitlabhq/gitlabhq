export const getKey = (name) => `$_gl_jest_${name}`;

export const getBinding = (el, name) => el[getKey(name)];

const writeBindingToElement = (el, name, { value, arg, modifiers }) => {
  el[getKey(name)] = {
    value,
    arg,
    modifiers,
  };
};

export const createMockDirective = (name) => {
  if (!name) {
    throw new Error(
      'Vue 3 no longer passes the name of the directive to its hooks, an explicit name is required',
    );
  }

  return {
    bind(el, binding) {
      writeBindingToElement(el, name, binding);
    },

    update(el, binding) {
      writeBindingToElement(el, name, binding);
    },

    unbind(el) {
      delete el[getKey(name)];
    },
  };
};
