<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import {
  IMAGE_STATUS_MESSAGES,
  IMAGE_STATUS_TITLES,
  IMAGE_STATUS_ALERT_TYPE,
  PACKAGE_DELETE_HELP_PAGE_PATH,
} from '../../constants';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    message() {
      return IMAGE_STATUS_MESSAGES[this.status];
    },
    title() {
      return IMAGE_STATUS_TITLES[this.status];
    },
    variant() {
      return IMAGE_STATUS_ALERT_TYPE[this.status];
    },
  },
  links: {
    PACKAGE_DELETE_HELP_PAGE_PATH,
  },
};
</script>
<template>
  <gl-alert :title="title" :variant="variant">
    <span data-testid="message">
      <gl-sprintf :message="message">
        <template #link="{ content }">
          <gl-link :href="$options.links.PACKAGE_DELETE_HELP_PAGE_PATH" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </gl-alert>
</template>
