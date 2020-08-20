if (window.Range.prototype.getBoundingClientRect) {
  throw new Error('window.Range.prototype.getBoundingClientRect already exists. Remove this stub!');
}
window.Range.prototype.getBoundingClientRect = function getBoundingClientRect() {
  return { x: 0, y: 0, width: 0, height: 0, top: 0, right: 0, bottom: 0, left: 0 };
};

if (window.Range.prototype.getClientRects) {
  throw new Error('window.Range.prototype.getClientRects already exists. Remove this stub!');
}
window.Range.prototype.getClientRects = function getClientRects() {
  return [this.getBoundingClientRect()];
};
