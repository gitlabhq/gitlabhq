if (window.NodeList && !NodeList.prototype.forEach) {
  NodeList.prototype.forEach = function forEach(callback, thisArg = window) {
    for (let i = 0; i < this.length; i += 1) {
      callback.call(thisArg, this[i], i, this);
    }
  };
}
