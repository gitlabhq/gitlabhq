/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

export default class Doc extends Node {
  get name() {
    return 'doc';
  }

  get schema() {
    return {
      content: 'block+',
    };
  }
}
