/**
 * ReadMore
 *
 * Adds "read more" functionality to elements.
 *
 * Specifically, it looks for a trigger, by default ".js-read-more-trigger", and adds the class
 * "is-expanded" to the previous element in order to provide a click to expand functionality.
 *
 * This is useful for long text elements that you would like to truncate, especially for mobile.
 *
 * Example Markup
 * <div class="read-more-container">
 *   <p>Some text that should be long enough to have to truncate within a specified container.</p>
 *   <p>This text will not appear in the container, as only the first line can be truncated.</p>
 *   <p>This should also not appear, if everything is working correctly!</p>
 * </div>
 * <button class="js-read-more-trigger">Read more</button>
 *
 */
export default function initReadMore(triggerSelector = '.js-read-more-trigger') {
  const triggerEls = document.querySelectorAll(triggerSelector);

  if (!triggerEls) return;

  triggerEls.forEach((triggerEl) => {
    const targetEl = triggerEl.previousElementSibling;

    if (!targetEl) {
      return;
    }

    triggerEl.addEventListener(
      'click',
      (e) => {
        targetEl.classList.add('is-expanded');
        e.target.remove();
      },
      { once: true },
    );
  });
}
