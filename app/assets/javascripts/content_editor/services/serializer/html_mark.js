import { openTag, closeTag } from '../serialization_helpers';

const htmlMark = (name) => ({
  mixable: true,
  open(state, node) {
    return openTag(name, node.attrs);
  },
  close: closeTag(name),
});

export default htmlMark;
