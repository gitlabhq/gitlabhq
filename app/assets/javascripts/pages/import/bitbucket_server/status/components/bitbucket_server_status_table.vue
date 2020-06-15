<script>
import { GlButton } from '@gitlab/ui';
import BitbucketStatusTable from '~/import_projects/components/bitbucket_status_table.vue';

export default {
  components: {
    BitbucketStatusTable,
    GlButton,
  },
  props: {
    providerTitle: {
      type: String,
      required: true,
    },
    reconfigurePath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <bitbucket-status-table :provider-title="providerTitle">
    <template #actions>
      <gl-button variant="info" class="gl-ml-3" data-method="post" :href="reconfigurePath">{{
        __('Reconfigure')
      }}</gl-button>
    </template>
  </bitbucket-status-table>
</template>
