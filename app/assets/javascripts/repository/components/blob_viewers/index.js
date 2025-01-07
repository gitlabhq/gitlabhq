export const viewers = {
  csv: () => import('./csv_viewer.vue'),
  download: () => import('jh_else_ce/repository/components/blob_viewers/download_viewer.vue'),
  image: () => import('./image_viewer.vue'),
  video: () => import('./video_viewer.vue'),
  empty: () => import('./empty_viewer.vue'),
  text: () => import('~/vue_shared/components/source_viewer/source_viewer.vue'),
  pdf: () => import('jh_else_ce/repository/components/blob_viewers/pdf_viewer.vue'),
  lfs: () => import('jh_else_ce/repository/components/blob_viewers/lfs_viewer.vue'),
  audio: () => import('./audio_viewer.vue'),
  svg: () => import('./image_viewer.vue'),
  sketch: () => import('./sketch_viewer.vue'),
  notebook: () => import('./notebook_viewer.vue'),
  openapi: () => import('./openapi_viewer.vue'),
  geo_json: () => import('./geo_json/geo_json_viewer.vue'),
  too_large: () => import('./too_large_viewer.vue'),
};

export const loadViewer = (type, isUsingLfs, isTooLarge) => {
  let viewer = viewers[type];

  if (isTooLarge) {
    viewer = viewers.too_large;
  } else if (!viewer && isUsingLfs) {
    viewer = viewers.lfs;
  }

  return viewer;
};
