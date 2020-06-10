<script>
import { GlEmptyState } from '@gitlab/ui';
import {
  EMPTY_IMAGE_REPOSITORY_TITLE,
  EMPTY_IMAGE_REPOSITORY_MESSAGE,
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
  },
  i18n: {
    EMPTY_IMAGE_REPOSITORY_TITLE,
    EMPTY_IMAGE_REPOSITORY_MESSAGE,
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.EMPTY_IMAGE_REPOSITORY_TITLE"
    :svg-path="noContainersImage"
    :description="$options.i18n.EMPTY_IMAGE_REPOSITORY_MESSAGE"
    class="gl-mx-auto gl-my-0"
  />
</template>
