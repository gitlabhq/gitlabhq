import { __ } from '~/locale';

const viewers = {
  image: {
    id: 'image',
    binary: true,
  },
  markdown: {
    id: 'markdown',
    previewTitle: __('Preview Markdown'),
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
  const extension = name.includes('.') && name.split('.').pop();
  const viewerName = fileNameViewers[name] || fileExtensionViewers[extension];

  return viewers[viewerName];
}

export default viewers;
