<script>
import { GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import {
  TYPE_ALERT,
  TYPE_EPIC,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  TYPE_TEST_CASE,
} from '~/issues/constants';

export const i18n = Object.freeze({
  alertMessage: __(
    "Someone edited the %{issuableType} at the same time you did. Review %{linkStart}the %{issuableType}%{linkEnd} and make sure you don't unintentionally overwrite their changes.",
  ),
});

export default {
  components: {
    GlSprintf,
    GlLink,
    GlAlert,
  },
  props: {
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [TYPE_ALERT, TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST, TYPE_TEST_CASE].includes(
          value,
        );
      },
    },
  },
  computed: {
    currentPath() {
      return window.location.pathname;
    },
    alertMessage() {
      return sprintf(this.$options.i18n.alertMessage, { issuableType: this.issuableType });
    },
  },
  i18n,
};
</script>

<template>
  <gl-alert variant="danger" class="gl-mb-5" :dismissible="false">
    <gl-sprintf :message="alertMessage">
      <template #link="{ content }">
        <gl-link :href="currentPath" target="_blank" rel="nofollow">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
