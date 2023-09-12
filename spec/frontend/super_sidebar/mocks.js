export const moveMouse = (clientX) => {
  const event = new MouseEvent('mousemove', {
    clientX,
  });

  document.dispatchEvent(event);
};

export const mouseEnter = (el) => {
  const event = new MouseEvent('mouseenter');

  el.dispatchEvent(event);
};

export const mouseLeave = (el) => {
  const event = new MouseEvent('mouseleave');

  el.dispatchEvent(event);
};

export const moveMouseOutOfDocument = () => {
  const event = new MouseEvent('mouseleave');
  document.documentElement.dispatchEvent(event);
};
