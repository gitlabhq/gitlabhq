<script>
import { GlButton } from '@gitlab/ui';
import BitbucketStatusTable from '~/import_entities/import_projects/components/bitbucket_status_table.vue';

export default {
  components: {
    BitbucketStatusTable,
    GlButton,
  },
  inheritAttrs: false,
  props: {
    reconfigurePath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <bitbucket-status-table v-bind="$attrs">
    <template #actions>
      <gl-button
        category="secondary"
        variant="confirm"
        class="gl-ml-3"
        data-method="post"
        :href="reconfigurePath"
        >{{ __('Reconfigure') }}</gl-button
      >
    </template>
  </bitbucket-status-table>
</template>
