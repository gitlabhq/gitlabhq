import { spriteIcon } from '~/lib/utils/common_utils';

/**
 * This adds interactivity to accordions created via HAML
 */
export default (el) => {
  if (!el) return;

  const accordionTrigger = el.querySelector('button');
  const accordionItem = el.querySelector('.accordion-item');
  const iconClass = 's16 gl-icon gl-button-icon js-chevron-icon';
  const chevronRight = spriteIcon('chevron-right', iconClass);
  const chevronDown = spriteIcon('chevron-down', iconClass);

  accordionTrigger.addEventListener('click', () => {
    const chevronIcon = el.querySelector('.js-chevron-icon');
    accordionItem.classList.toggle('show');

    if (accordionItem.classList.contains('show')) {
      // eslint-disable-next-line no-unsanitized/property
      chevronIcon.outerHTML = chevronDown;
      accordionTrigger.setAttribute('aria-expanded', 'true');
      return;
    }

    // eslint-disable-next-line no-unsanitized/property
    chevronIcon.outerHTML = chevronRight;
    accordionTrigger.setAttribute('aria-expanded', 'false');
  });
};
