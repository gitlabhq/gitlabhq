import { preserveUnchanged } from '../serialization_helpers';

const tableOfContents = preserveUnchanged((state, node) => {
  state.write('[[_TOC_]]');
  state.closeBlock(node);
});

export default tableOfContents;
