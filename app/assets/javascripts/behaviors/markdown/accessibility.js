import { __, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';

function addAriaLabels(checkboxes) {
  checkboxes.forEach((checkbox) => {
    // If we already get the ariaLabel from RTE, return
    if (!checkbox || checkbox.hasAttribute('aria-label')) return;

    const li = checkbox.closest('li').cloneNode(true);
    li.querySelector('ul')?.remove();
    const textContent = li?.textContent?.trim();

    checkbox.setAttribute(
      'aria-label',
      sprintf(__('Check option: %{option}'), {
        option: truncate(textContent, 100),
      }),
    );
  });
}

export { addAriaLabels };
