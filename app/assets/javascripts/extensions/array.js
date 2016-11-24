/* eslint-disable no-extend-native, func-names, space-before-function-paren, semi, space-infix-ops, max-len */
Array.prototype.first = function() {
  return this[0];
}

Array.prototype.last = function() {
  return this[this.length-1];
}
