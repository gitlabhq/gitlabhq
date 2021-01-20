import { joinPaths } from '~/lib/utils/url_utility';

export const updateElementsVisibility = (selector, isVisible) => {
  document
    .querySelectorAll(selector)
    .forEach((elem) => elem.classList.toggle('hidden', !isVisible));
};

export const updateFormAction = (selector, basePath, path) => {
  const form = document.querySelector(selector);

  if (form) {
    form.action = joinPaths(basePath, path);
  }
};
