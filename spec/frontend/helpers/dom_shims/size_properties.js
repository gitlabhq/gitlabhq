const convertFromStyle = (style) => {
  if (style.match(/[0-9](px|rem)/g)) {
    return Number(style.replace(/[^0-9]/g, ''));
  }

  return 0;
};

Object.defineProperty(global.HTMLElement.prototype, 'offsetWidth', {
  get() {
    return convertFromStyle(this.style.width || '0px');
  },
});

Object.defineProperty(global.HTMLElement.prototype, 'offsetHeight', {
  get() {
    return convertFromStyle(this.style.height || '0px');
  },
});
