Element.prototype.scrollTo = jest.fn().mockImplementation(function scrollTo(x, y) {
  this.scrollLeft = x;
  this.scrollTop = y;

  this.dispatchEvent(new Event('scroll'));
});
