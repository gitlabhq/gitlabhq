// TODO: remove this

// eslint-disable-next-line no-extend-native
Array.prototype.first = function first() {
  return this[0];
};

// eslint-disable-next-line no-extend-native
Array.prototype.last = function last() {
  return this[this.length - 1];
};
