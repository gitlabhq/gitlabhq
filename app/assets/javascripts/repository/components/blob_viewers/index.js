export const loadViewer = (type) => {
  switch (type) {
    case 'empty':
      return () => import(/* webpackChunkName: 'blob_empty_viewer' */ './empty_viewer.vue');
    case 'text':
      return gon.features.highlightJs
        ? () =>
            import(
              /* webpackChunkName: 'blob_text_viewer' */ '~/vue_shared/components/source_viewer.vue'
            )
        : null;
    case 'download':
      return () => import(/* webpackChunkName: 'blob_download_viewer' */ './download_viewer.vue');
    case 'image':
      return () => import(/* webpackChunkName: 'blob_image_viewer' */ './image_viewer.vue');
    case 'video':
      return () => import(/* webpackChunkName: 'blob_video_viewer' */ './video_viewer.vue');
    case 'pdf':
      return () => import(/* webpackChunkName: 'blob_pdf_viewer' */ './pdf_viewer.vue');
    default:
      return null;
  }
};

export const viewerProps = (type, blob) => {
  return {
    text: {
      content: blob.rawTextBlob,
      autoDetect: true, // We'll eventually disable autoDetect and pass the language explicitly to reduce the footprint (https://gitlab.com/gitlab-org/gitlab/-/issues/348145)
    },
    download: {
      fileName: blob.name,
      filePath: blob.rawPath,
      fileSize: blob.rawSize,
    },
    image: {
      url: blob.rawPath,
      alt: blob.name,
    },
    video: {
      url: blob.rawPath,
    },
    pdf: {
      url: blob.rawPath,
      fileSize: blob.rawSize,
    },
  }[type];
};
