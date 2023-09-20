<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { STATUS_TYPES, UPGRADE_DOCS_URL } from '../constants';

export default {
  name: 'GitlabVersionCheckBadge',
  components: {
    GlBadge,
  },
  mixins: [Tracking.mixin()],
  props: {
    size: {
      type: String,
      required: false,
      default: 'md',
    },
    actionable: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      if (this.status === STATUS_TYPES.SUCCESS) {
        return s__('VersionCheck|Up to date');
      }
      if (this.status === STATUS_TYPES.WARNING) {
        return s__('VersionCheck|Update available');
      }
      if (this.status === STATUS_TYPES.DANGER) {
        return s__('VersionCheck|Update ASAP');
      }

      return null;
    },
    badgeUrl() {
      return this.actionable ? UPGRADE_DOCS_URL : null;
    },
  },
  mounted() {
    this.track('render', {
      label: 'version_badge',
      property: this.title,
    });
  },
  methods: {
    onClick() {
      if (!this.actionable) return;

      this.track('click_link', {
        label: 'version_badge',
        property: this.title,
      });
    },
  },
  UPGRADE_DOCS_URL,
};
</script>

<template>
  <!-- TODO: remove the span element once bootstrap-vue is updated to version 2.21.1 -->
  <!-- TODO: https://github.com/bootstrap-vue/bootstrap-vue/issues/6219 -->
  <span data-testid="badge-click-wrapper" @click="onClick">
    <gl-badge :href="badgeUrl" class="version-check-badge" :variant="status" :size="size">{{
      title
    }}</gl-badge>
  </span>
</template>
