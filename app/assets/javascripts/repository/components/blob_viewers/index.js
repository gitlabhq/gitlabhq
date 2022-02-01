const viewers = {
  download: () => import('./download_viewer.vue'),
  image: () => import('./image_viewer.vue'),
  video: () => import('./video_viewer.vue'),
  empty: () => import('./empty_viewer.vue'),
  text: () => import('~/vue_shared/components/source_viewer.vue'),
  pdf: () => import('./pdf_viewer.vue'),
  lfs: () => import('./lfs_viewer.vue'),
};

export const loadViewer = (type, isUsingLfs) => {
  let viewer = viewers[type];

  if (!viewer && isUsingLfs) {
    viewer = viewers.lfs;
  }

  return viewer;
};

export const viewerProps = (type, blob) => {
  const props = {
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
    lfs: {
      fileName: blob.name,
      filePath: blob.rawPath,
    },
  };

  return props[type] || props[blob.externalStorage];
};
