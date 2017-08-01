let hideTimeoutInterval = 0;
let hideTimeout;
let subitems;

export const getHideTimeoutInterval = () => hideTimeoutInterval;

export const hideAllSubItems = () => {
  subitems.forEach((el) => {
    el.parentNode.classList.remove('is-over');
    el.style.display = 'none'; // eslint-disable-line no-param-reassign
  });
};

export const calculateTop = (boundingRect, outerHeight) => {
  const windowHeight = window.innerHeight;
  const bottomOverflow = windowHeight - (boundingRect.top + outerHeight);

  return bottomOverflow < 0 ? (boundingRect.top - outerHeight) + boundingRect.height :
    boundingRect.top;
};

export const showSubLevelItems = (el) => {
  const $subitems = el.querySelector('.sidebar-sub-level-items');

  if (!$subitems) return;

  hideAllSubItems();

  if (el.classList.contains('is-over')) {
    clearTimeout(hideTimeout);
  } else {
    $subitems.style.display = 'block';
    el.classList.add('is-over');
  }

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
  const hideFn = () => {
    el.classList.remove('is-over');
    $subitems.style.display = 'none';
    $subitems.classList.remove('is-above');

    hideTimeoutInterval = 0;
  };

  if ($subitems && hideTimeoutInterval) {
    hideTimeout = setTimeout(hideFn, hideTimeoutInterval);
  } else if ($subitems) {
    hideFn();
  }
};

export const setMouseOutTimeout = (el) => {
  if (el.closest('.sidebar-sub-level-items')) {
    hideTimeoutInterval = 250;
  } else {
    hideTimeoutInterval = 0;
  }
};

export default () => {
  const items = [...document.querySelectorAll('.sidebar-top-level-items > li:not(.active)')];
  subitems = [...document.querySelectorAll('.sidebar-top-level-items > li:not(.active) .sidebar-sub-level-items')];

  items.forEach((el) => {
    el.addEventListener('mouseenter', e => showSubLevelItems(e.currentTarget));
    el.addEventListener('mouseleave', e => hideSubLevelItems(e.currentTarget));
  });

  subitems.forEach(el => el.addEventListener('mouseleave', e => setMouseOutTimeout(e.target)));
};
