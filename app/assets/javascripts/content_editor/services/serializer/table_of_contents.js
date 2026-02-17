function tableOfContents(state, node) {
  state.write('[[_TOC_]]');
  state.closeBlock(node);
}

export default tableOfContents;
