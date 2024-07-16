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
  <gl-badge
    :href="badgeUrl"
    class="gl-align-middle"
    :variant="status"
    data-testid="check-version-badge"
    @click.native="onClick"
    >{{ title }}</gl-badge
  >
</template>
