export const getKey = name => `$_gl_jest_${name}`;

export const getBinding = (el, name) => el[getKey(name)];

const writeBindingToElement = (el, { name, value, arg, modifiers }) => {
  el[getKey(name)] = {
    value,
    arg,
    modifiers,
  };
};

export const createMockDirective = () => ({
  bind(el, binding) {
    writeBindingToElement(el, binding);
  },

  update(el, binding) {
    writeBindingToElement(el, binding);
  },

  unbind(el, { name }) {
    delete el[getKey(name)];
  },
});
