const hide = (el) => el.classList.add('!gl-hidden');
const show = (el) => el.classList.remove('!gl-hidden');

const setupCollapsibleInput = (el) => {
  const collapsedEl = el.querySelector('.js-collapsed');
  const expandedEl = el.querySelector('.js-expanded');
  const collapsedInputEl = collapsedEl.querySelector('textarea,input,select');
  const expandedInputEl = expandedEl.querySelector('textarea,input,select');
  const formEl = el.closest('form');

  const collapse = () => {
    hide(expandedEl);
    show(collapsedEl);
  };

  const expand = () => {
    hide(collapsedEl);
    show(expandedEl);
  };

  // NOTE:
  // We add focus listener to all form inputs so that we can collapse
  // when something is focused that's not the expanded input.
  formEl.addEventListener('focusin', (e) => {
    if (e.target === collapsedInputEl) {
      expand();
      expandedInputEl.focus();
    } else if (!el.contains(e.target) && !expandedInputEl.value) {
      collapse();
    }
  });
};

/**
 * Usage in HAML
 *
 * .js-collapsible-input
 *   .js-collapsed{ class: ('!gl-hidden' if is_expanded) }
 *     = input
 *   .js-expanded{ class: ('!gl-hidden' if !is_expanded) }
 *     = big_input
 */
export default () => {
  Array.from(document.querySelectorAll('.js-collapsible-input')).forEach(setupCollapsibleInput);
};
