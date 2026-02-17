export const observeIntersectionOnce = (element) => {
  return new Promise((resolve) => {
    const observer = new IntersectionObserver(([entry]) => {
      resolve(entry);
      observer.disconnect();
    });
    observer.observe(element);
  });
};

export const getCoveringElement = async (element) => {
  const { top, left } = (await observeIntersectionOnce(element)).intersectionRect;
  // browser might compensate for sticky element border, we should shift the target by 1px because of this
  const topElement = document.elementFromPoint(left, top + 1);

  if (!topElement || topElement === element || element.contains(topElement)) return null;

  let current = topElement;
  while (current && current !== document.body) {
    const { position } = getComputedStyle(current);
    if (position === 'sticky' || position === 'fixed') return current;
    current = current.offsetParent;
  }

  return null;
};
