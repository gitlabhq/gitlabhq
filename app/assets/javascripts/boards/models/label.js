import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default class ListLabel {
  constructor(obj) {
    Object.assign(this, convertObjectPropsToCamelCase(obj, { dropKeys: ['priority'] }), {
      priority: obj.priority !== null ? obj.priority : Infinity,
    });
  }
}

window.ListLabel = ListLabel;
