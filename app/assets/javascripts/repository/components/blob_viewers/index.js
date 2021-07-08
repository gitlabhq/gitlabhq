export const loadViewer = (type) => {
  switch (type) {
    case 'empty':
      return () => import(/* webpackChunkName: 'blob_empty_viewer' */ './empty_viewer.vue');
    case 'text':
      return () => import(/* webpackChunkName: 'blob_text_viewer' */ './text_viewer.vue');
    case 'download':
      // TODO (follow-up): import the download viewer
      return null; // () => import(/* webpackChunkName: 'blob_download_viewer' */ './download_viewer.vue');
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
  }[type];
};
