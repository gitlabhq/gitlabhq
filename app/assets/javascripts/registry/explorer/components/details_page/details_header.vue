<script>
import { GlSprintf } from '@gitlab/ui';
import { DETAILS_PAGE_TITLE } from '../../constants/index';

export default {
  components: { GlSprintf },
  props: {
    imageName: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    DETAILS_PAGE_TITLE,
  },
};
</script>

<template>
  <div class="gl-display-flex gl-my-2 gl-align-items-center">
    <h4>
      <gl-sprintf :message="$options.i18n.DETAILS_PAGE_TITLE">
        <template #imageName>
          {{ imageName }}
        </template>
      </gl-sprintf>
    </h4>
  </div>
</template>
