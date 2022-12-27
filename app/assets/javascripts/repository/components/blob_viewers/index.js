const viewers = {
  csv: () => import('./csv_viewer.vue'),
  download: () => import('./download_viewer.vue'),
  image: () => import('./image_viewer.vue'),
  video: () => import('./video_viewer.vue'),
  empty: () => import('./empty_viewer.vue'),
  text: () => import('~/vue_shared/components/source_viewer/source_viewer.vue'),
  pdf: () => import('./pdf_viewer.vue'),
  lfs: () => import('./lfs_viewer.vue'),
  audio: () => import('./audio_viewer.vue'),
  svg: () => import('./image_viewer.vue'),
  sketch: () => import('./sketch_viewer.vue'),
  notebook: () => import('./notebook_viewer.vue'),
};

export const loadViewer = (type, isUsingLfs) => {
  let viewer = viewers[type];

  if (!viewer && isUsingLfs) {
    viewer = viewers.lfs;
  }

  return viewer;
};
