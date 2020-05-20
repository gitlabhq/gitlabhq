/**
 * Returns true if the given module is required from eslint
 */
const isESLint = mod => {
  let parent = mod.parent;

  while (parent) {
    if (parent.filename.includes('/eslint')) {
      return true;
    }

    parent = parent.parent;
  }

  return false;
};

module.exports = isESLint;
