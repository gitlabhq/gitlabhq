export const calculateTop = (boundingRect, outerHeight) => {
  const windowHeight = window.innerHeight;
  const bottomOverflow = windowHeight - (boundingRect.top + outerHeight);

  return bottomOverflow < 0 ? (boundingRect.top - outerHeight) + boundingRect.height :
    boundingRect.top;
};

export const showSubLevelItems = (el) => {
  const $subitems = el.querySelector('.sidebar-sub-level-items');

  if (!$subitems) return;

  $subitems.style.display = 'block';
  el.classList.add('is-over');

  const boundingRect = el.getBoundingClientRect();
  const top = calculateTop(boundingRect, $subitems.offsetHeight);
  const isAbove = top < boundingRect.top;

  $subitems.style.transform = `translate3d(0, ${top}px, 0)`;

  if (isAbove) {
    $subitems.classList.add('is-above');
  }
};

export const hideSubLevelItems = (el) => {
  const $subitems = el.querySelector('.sidebar-sub-level-items');

  if (!$subitems) return;

  el.classList.remove('is-over');
  $subitems.style.display = 'none';
  $subitems.classList.remove('is-above');
};

export default () => {
  const items = [...document.querySelectorAll('.sidebar-top-level-items > li:not(.active)')]
    .filter(el => el.querySelector('.sidebar-sub-level-items'));

  items.forEach((el) => {
    el.addEventListener('mouseenter', e => showSubLevelItems(e.currentTarget));
    el.addEventListener('mouseleave', e => hideSubLevelItems(e.currentTarget));
  });
};
