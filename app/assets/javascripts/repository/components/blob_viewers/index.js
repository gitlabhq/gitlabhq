export const loadViewer = (type) => {
  switch (type) {
    case 'empty':
      return () => import(/* webpackChunkName: 'blob_empty_viewer' */ './empty_viewer.vue');
    case 'text':
      return () => import(/* webpackChunkName: 'blob_text_viewer' */ './text_viewer.vue');
    case 'download':
      return () => import(/* webpackChunkName: 'blob_download_viewer' */ './download_viewer.vue');
    default:
      return null;
  }
};

export const viewerProps = (type, blob) => {
  return {
    text: {
      content: blob.rawTextBlob,
      fileName: blob.name,
      readOnly: true,
    },
    download: {
      fileName: blob.name,
      filePath: blob.rawPath,
      fileSize: blob.rawSize,
    },
  }[type];
};
