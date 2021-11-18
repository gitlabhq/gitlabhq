<script>
import { GlEmptyState } from '@gitlab/ui';
import {
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  MISSING_OR_DELETED_IMAGE_TITLE,
  MISSING_OR_DELETED_IMAGE_MESSAGE,
} from '../../constants/index';

export default {
  components: {
    GlEmptyState,
  },
  props: {
    noContainersImage: {
      type: String,
      required: false,
      default: '',
    },
    isEmptyImage: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    title() {
      return this.isEmptyImage ? MISSING_OR_DELETED_IMAGE_TITLE : NO_TAGS_TITLE;
    },
    description() {
      return this.isEmptyImage ? MISSING_OR_DELETED_IMAGE_MESSAGE : NO_TAGS_MESSAGE;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="title"
    :svg-path="noContainersImage"
    :description="description"
    class="gl-mx-auto gl-my-0"
  />
</template>
