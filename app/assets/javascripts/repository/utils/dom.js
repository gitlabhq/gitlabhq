export const updateElementsVisibility = (selector, isVisible) => {
  document.querySelectorAll(selector).forEach(elem => elem.classList.toggle('hidden', !isVisible));
};

export const updateFormAction = (selector, basePath, path) => {
  const form = document.querySelector(selector);

  if (form) {
    form.action = `${basePath}${path}`;
  }
};
