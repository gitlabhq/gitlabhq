function normalizeNewlines(str) {
  return str.replace(/(\r|&#x000D;)?(\n|&#x000A;)/g, '\n');
}

export default normalizeNewlines;
