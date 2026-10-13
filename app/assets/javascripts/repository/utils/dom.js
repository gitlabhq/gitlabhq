export const updateElementsVisibility = (selector, isVisible) => {
  document
    .querySelectorAll(selector)
    .forEach((elem) => elem.classList.toggle('hidden', !isVisible));
};
