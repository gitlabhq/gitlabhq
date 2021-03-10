/**
 * Returns true if the given module is required from eslint
 */
const isESLint = (mod) => {
  let { parent } = mod;

  while (parent) {
    if (parent.filename && parent.filename.includes('/eslint')) {
      return true;
    }

    parent = parent.parent;
  }

  return false;
};

module.exports = isESLint;
