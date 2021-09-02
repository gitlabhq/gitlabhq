<script>
// This file is in progress and behind a feature flag, please see the following issue for more:
// https://gitlab.com/gitlab-org/gitlab/-/issues/323200

import BlobContentViewer from '../components/blob_content_viewer.vue';
import { LIMITED_CONTAINER_WIDTH_CLASS } from '../constants';

export default {
  components: {
    BlobContentViewer,
  },
  beforeRouteEnter(to, from, next) {
    next(({ $options }) => {
      $options.limitedContainerElements.forEach((el) =>
        el.classList.remove(LIMITED_CONTAINER_WIDTH_CLASS),
      );
    });
  },
  beforeRouteLeave(to, from, next) {
    this.$options.limitedContainerElements.forEach((el) =>
      el.classList.add(LIMITED_CONTAINER_WIDTH_CLASS),
    );
    next();
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  limitedContainerElements: document.querySelectorAll(`.${LIMITED_CONTAINER_WIDTH_CLASS}`),
};
</script>

<template>
  <blob-content-viewer :path="path" :project-path="projectPath" />
</template>
