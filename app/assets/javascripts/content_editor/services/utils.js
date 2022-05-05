export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};

/**
 * Extracts filename from a URL
 *
 * @example
 *   > extractFilename('https://gitlab.com/images/logo-full.png')
 *   < 'logo-full'
 *
 * @param {string} src The URL to extract filename from
 * @returns {string}
 */
export const extractFilename = (src) => {
  return src.replace(/^.*\/|\.[^.]+?$/g, '');
};

export const readFileAsDataURL = (file) => {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.addEventListener('load', (e) => resolve(e.target.result), { once: true });
    reader.readAsDataURL(file);
  });
};

export const clamp = (n, min, max) => Math.max(Math.min(n, max), min);
