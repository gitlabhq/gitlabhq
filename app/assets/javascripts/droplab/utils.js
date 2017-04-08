/* eslint-disable */

import { DATA_TRIGGER, DATA_DROPDOWN } from './constants';

const utils = {
  toCamelCase(attr) {
    return this.camelize(attr.split('-').slice(1).join(' '));
  },

  t(s, d) {
    for (const p in d) {
      if (Object.prototype.hasOwnProperty.call(d, p)) {
        s = s.replace(new RegExp(`{{${p}}}`, 'g'), d[p]);
      }
    }
    return s;
  },

  camelize(str) {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) => {
      return index === 0 ? letter.toLowerCase() : letter.toUpperCase();
    }).replace(/\s+/g, '');
  },

  closest(thisTag, stopTag) {
    while (thisTag && thisTag.tagName !== stopTag && thisTag.tagName !== 'HTML') {
      thisTag = thisTag.parentNode;
    }
    return thisTag;
  },

  isDropDownParts(target) {
    if (!target || target.tagName === 'HTML') return false;
    return target.hasAttribute(DATA_TRIGGER) || target.hasAttribute(DATA_DROPDOWN);
  },
};

export default utils;
