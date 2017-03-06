/* eslint-disable no-extend-native, func-names, space-before-function-paren, space-infix-ops, strict, max-len */

'use strict';

Array.prototype.first = function() {
  return this[0];
};

Array.prototype.last = function() {
  return this[this.length-1];
};

Array.prototype.find = Array.prototype.find || function(predicate, ...args) {
  if (!this) throw new TypeError('Array.prototype.find called on null or undefined');
  if (typeof predicate !== 'function') throw new TypeError('predicate must be a function');

  const list = Object(this);
  const thisArg = args[1];
  let value = {};

  for (let i = 0; i < list.length; i += 1) {
    value = list[i];
    if (predicate.call(thisArg, value, i, list)) return value;
  }

  return undefined;
};
