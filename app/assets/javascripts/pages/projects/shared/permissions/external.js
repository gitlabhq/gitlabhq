const selectorCache = [];

// workaround since we don't have a polyfill for classList.toggle 2nd parameter
export function toggleHiddenClass(element, hidden) {
  if (hidden) {
    element.classList.add('hidden');
  } else {
    element.classList.remove('hidden');
  }
}

// hide external feature-specific settings when a given feature is disabled
export function toggleHiddenClassBySelector(selector, hidden) {
  if (!selectorCache[selector]) {
    selectorCache[selector] = document.querySelectorAll(selector);
  }
  selectorCache[selector].forEach(elm => toggleHiddenClass(elm, hidden));
}
