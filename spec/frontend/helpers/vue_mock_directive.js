export const getKey = name => `$_gl_jest_${name}`;

export const getBinding = (el, name) => el[getKey(name)];

export const createMockDirective = () => ({
  bind(el, { name, value, arg, modifiers }) {
    el[getKey(name)] = {
      value,
      arg,
      modifiers,
    };
  },

  unbind(el, { name }) {
    delete el[getKey(name)];
  },
});
