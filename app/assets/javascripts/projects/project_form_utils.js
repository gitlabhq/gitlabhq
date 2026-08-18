export const setOrRemoveAttribute = (el, name, value) => {
  if (value == null) {
    el.removeAttribute(name);
  } else {
    el.setAttribute(name, value);
  }
};
