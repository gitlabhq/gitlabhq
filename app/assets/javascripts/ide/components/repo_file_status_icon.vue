<script>
import { GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import '~/lib/utils/datetime_utility';

export default {
  components: {
    GlIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    lockTooltip() {
      return sprintf(__(`Locked by %{fileLockUserName}`), {
        fileLockUserName: this.file.file_lock.user.name,
      });
    },
  },
};
</script>

<template>
  <span v-if="file.file_lock" v-tooltip :title="lockTooltip" data-container="body">
    <gl-icon name="lock" class="file-status-icon" />
  </span>
</template>
