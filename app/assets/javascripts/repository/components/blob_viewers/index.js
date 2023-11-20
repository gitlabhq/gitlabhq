import { TEXT_FILE_TYPE } from '../../constants';

export const viewers = {
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
  openapi: () => import('./openapi_viewer.vue'),
  geo_json: () => import('./geo_json/geo_json_viewer.vue'),
};

export const loadViewer = (type, isUsingLfs, hljsWorkerEnabled) => {
  let viewer = viewers[type];

  if (hljsWorkerEnabled && type === TEXT_FILE_TYPE) {
    viewer = () => import('~/vue_shared/components/source_viewer/source_viewer_new.vue');
  }

  if (!viewer && isUsingLfs) {
    viewer = viewers.lfs;
  }

  return viewer;
};
