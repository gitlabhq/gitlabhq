<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';

const STATUS_TYPES = {
  SUCCESS: 'success',
  WARNING: 'warning',
  DANGER: 'danger',
};

const UPGRADE_DOCS_URL = helpPagePath('update/index');

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
        .get(joinPaths('/', gon.relative_url_root, '/admin/version_check.json'))
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
  UPGRADE_DOCS_URL,
};
</script>

<template>
  <gl-badge
    v-if="status"
    :href="$options.UPGRADE_DOCS_URL"
    class="version-check-badge"
    :variant="status"
    :size="size"
    >{{ title }}</gl-badge
  >
</template>
