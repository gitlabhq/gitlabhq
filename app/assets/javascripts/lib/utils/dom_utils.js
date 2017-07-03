/* eslint-disable import/prefer-default-export */

export const addClassIfElementExists = (element, className) => {
  if (element) {
    element.classList.add(className);
  }
};
