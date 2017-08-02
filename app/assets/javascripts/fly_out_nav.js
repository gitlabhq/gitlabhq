/* global bp */
import './breakpoints';

export const canShowSubItems = () => bp.getBreakpointSize() === 'md' || bp.getBreakpointSize() === 'lg';

export const calculateTop = (boundingRect, outerHeight) => {
  const windowHeight = window.innerHeight;
  const bottomOverflow = windowHeight - (boundingRect.top + outerHeight);

  return bottomOverflow < 0 ? (boundingRect.top - outerHeight) + boundingRect.height :
    boundingRect.top;
};

export const showSubLevelItems = (el) => {
  const subItems = el.querySelector('.sidebar-sub-level-items');

  if (!subItems || !canShowSubItems()) return;

  subItems.style.display = 'block';
  el.classList.add('is-over');

  const boundingRect = el.getBoundingClientRect();
  const top = calculateTop(boundingRect, subItems.offsetHeight);
  const isAbove = top < boundingRect.top;

  subItems.style.transform = `translate3d(0, ${Math.floor(top)}px, 0)`;

  if (isAbove) {
    subItems.classList.add('is-above');
  }
};

export const hideSubLevelItems = (el) => {
  const subItems = el.querySelector('.sidebar-sub-level-items');

  if (!subItems || !canShowSubItems()) return;

  el.classList.remove('is-over');
  subItems.style.display = 'none';
  subItems.classList.remove('is-above');
};

export default () => {
  const items = [...document.querySelectorAll('.sidebar-top-level-items > li:not(.active)')]
    .filter(el => el.querySelector('.sidebar-sub-level-items'));

  items.forEach((el) => {
    el.addEventListener('mouseenter', e => showSubLevelItems(e.currentTarget));
    el.addEventListener('mouseleave', e => hideSubLevelItems(e.currentTarget));
  });
};
