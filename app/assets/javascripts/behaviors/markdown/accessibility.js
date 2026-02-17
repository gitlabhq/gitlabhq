import { __, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';

// Adds aria-labels to task list items that lack it in the HTML rendered by the backend.
// We have done this in the backend since July 2025
// (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194823),
// so this exists to catch any cached content that hasn't been changed since then.
function addAriaLabels(checkboxes) {
  checkboxes.forEach((checkbox) => {
    if (!checkbox || checkbox.hasAttribute('aria-label')) return;

    const parent = checkbox.closest('li');
    if (!parent) return;

    const cloned = parent.cloneNode(true);
    cloned.querySelector('ul, ol')?.remove();
    const textContent = cloned?.textContent?.trim();

    if (textContent?.length) {
      checkbox.setAttribute(
        'aria-label',
        sprintf(__('Check option: %{option}'), {
          option: truncate(textContent, 100),
        }),
      );
    }
  });
}

export { addAriaLabels };
