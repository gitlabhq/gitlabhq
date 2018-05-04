const viewers = {
  image: {
    id: 'image',
  },
  markdown: {
    id: 'markdown',
    previewTitle: 'Preview Markdown',
  },
};

const fileNameViewers = {};
const fileExtensionViewers = {
  jpg: 'image',
  jpeg: 'image',
  gif: 'image',
  png: 'image',
  bmp: 'image',
  ico: 'image',
  md: 'markdown',
  markdown: 'markdown',
};

export function viewerInformationForPath(path) {
  if (!path) return null;
  const name = path.split('/').pop();
  const viewerName =
    fileNameViewers[name] || fileExtensionViewers[name ? name.split('.').pop() : ''] || '';

  return viewers[viewerName];
}

export default viewers;
