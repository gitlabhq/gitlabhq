export const loadViewer = (type) => {
  switch (type) {
    case 'empty':
      // TODO (follow-up): import the empty viewer
      return null; // () => import(/* webpackChunkName: 'blob_empty_viewer' */ './empty_viewer.vue');
    case 'text':
      // TODO (follow-up): import the text viewer
      return null; // () => import(/* webpackChunkName: 'blob_text_viewer' */ './text_viewer.vue');
    case 'download':
      // TODO (follow-up): import the download viewer
      return null; // () => import(/* webpackChunkName: 'blob_download_viewer' */ './download_viewer.vue');
    default:
      return null;
  }
};
