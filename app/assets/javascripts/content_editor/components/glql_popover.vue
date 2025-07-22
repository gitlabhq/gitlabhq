<script>
import { GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    GlBadge,
    GlPopover,
    GlLink,
    LocalStorageSync,
  },
  props: {
    target: {
      type: String,
      required: true,
    },
    value: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    helpPagePath,
    setValue(val) {
      this.$emit('input', val);
    },
  },
};
</script>
<template>
  <local-storage-sync :value="value" storage-key="glql-popover-visible" @input="setValue">
    <gl-popover
      v-if="value"
      ref="glqlPopover"
      placement="top"
      :target="target"
      triggers="manual"
      :show-close-button="true"
      :show="value"
      @hidden="setValue(false)"
    >
      <template #title>
        <div class="gl-flex gl-items-center gl-justify-between gl-gap-3">
          {{ __('Introducing embedded views') }}
          <gl-badge
            variant="info"
            size="small"
            target="_blank"
            :href="helpPagePath('user/glql/_index')"
          >
            {{ __('New') }}
          </gl-badge>
        </div>
      </template>
      <template #default>
        <p>
          {{
            __(
              'Create dynamic tables and lists powered by GitLab Query Language (GLQL) to track issues, epics, and merge requests in real time.',
            )
          }}
        </p>
        <gl-link :href="helpPagePath('user/glql/_index')" target="_blank">
          {{ __('Get started with embedded views') }}
        </gl-link>
      </template>
    </gl-popover>
  </local-storage-sync>
</template>
