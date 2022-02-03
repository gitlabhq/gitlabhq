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
