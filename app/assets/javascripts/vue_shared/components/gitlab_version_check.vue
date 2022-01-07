<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

const STATUS_TYPES = {
  SUCCESS: 'success',
  WARNING: 'warning',
  DANGER: 'danger',
};

export default {
  name: 'GitlabVersionCheck',
  components: {
    GlBadge,
  },
  props: {
    size: {
      type: String,
      required: false,
      default: 'md',
    },
  },
  data() {
    return {
      status: null,
    };
  },
  computed: {
    title() {
      if (this.status === STATUS_TYPES.SUCCESS) {
        return s__('VersionCheck|Up to date');
      } else if (this.status === STATUS_TYPES.WARNING) {
        return s__('VersionCheck|Update available');
      } else if (this.status === STATUS_TYPES.DANGER) {
        return s__('VersionCheck|Update ASAP');
      }

      return null;
    },
  },
  created() {
    this.checkGitlabVersion();
  },
  methods: {
    checkGitlabVersion() {
      axios
        .get('/admin/version_check.json')
        .then((res) => {
          if (res.data) {
            this.status = res.data.severity;
          }
        })
        .catch(() => {
          // Silently fail
          this.status = null;
        });
    },
  },
};
</script>

<template>
  <gl-badge v-if="status" class="version-check-badge" :variant="status" :size="size">{{
    title
  }}</gl-badge>
</template>
