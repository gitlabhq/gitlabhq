/* eslint-disable */

import { template as _template } from 'underscore';
import { DATA_TRIGGER, DATA_DROPDOWN, TEMPLATE_REGEX } from './constants';

const utils = {
  toCamelCase(attr) {
    return this.camelize(attr.split('-').slice(1).join(' '));
  },

  template(templateString, data) {
    const template = _template(templateString, {
      escape: TEMPLATE_REGEX,
    });

    return template(data);
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
    if (!target || !target.hasAttribute || target.tagName === 'HTML') return false;
    return target.hasAttribute(DATA_TRIGGER) || target.hasAttribute(DATA_DROPDOWN);
  },
};

export default utils;
