export const hasSelection = (tiptapEditor) => {
  const { from, to } = tiptapEditor.state.selection;

  return from < to;
};

export const getImageAlt = (src) => {
  return src.replace(/^.*\/|\..*$/g, '').replace(/\W+/g, ' ');
};

export const readFileAsDataURL = (file) => {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.addEventListener('load', (e) => resolve(e.target.result), { once: true });
    reader.readAsDataURL(file);
  });
};

export const clamp = (n, min, max) => Math.max(Math.min(n, max), min);
