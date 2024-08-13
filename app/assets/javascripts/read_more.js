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
 * If data-read-more-height is present it will use it to determine if the button should be shown or not.
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

    if (Object.hasOwn(triggerEl.parentNode.dataset, 'readMoreHeight')) {
      const parentEl = triggerEl.parentNode;
      const readMoreHeight = Number(parentEl.dataset.readMoreHeight);
      const readMoreContent = parentEl.querySelector('.read-more-content');

      // If element exists in readMoreContent expand content automatically
      // and scroll to element
      if (window.location.hash) {
        const targetId = window.location.href.split('#')[1];
        const hashTargetEl = readMoreContent.querySelector(`#user-content-${targetId}`);

        if (hashTargetEl) {
          targetEl.classList.add('is-expanded');
          triggerEl.remove();
          window.addEventListener('load', () => {
            // Trigger scrollTo event
            hashTargetEl.click();
          });
          return;
        }
      }

      if (readMoreContent) {
        parentEl.style.setProperty('--read-more-height', `${readMoreHeight}px`);
      }

      if (readMoreHeight > readMoreContent.clientHeight) {
        readMoreContent.classList.remove('read-more-content--has-scrim');
        triggerEl.remove();
        return;
      }

      triggerEl.classList.remove('gl-hidden');
    }

    triggerEl.addEventListener(
      'click',
      () => {
        targetEl.classList.add('is-expanded');
        triggerEl.remove();
      },
      { once: true },
    );
  });
}
