<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'PublishMethod',
  components: {
    ClipboardButton,
    GlIcon,
    GlLink,
  },
  props: {
    pipeline: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    hasPipeline() {
      return Boolean(this.pipeline);
    },
    packageShaShort() {
      return this.pipeline?.sha?.substring(0, 8);
    },
  },
  i18n: {
    COPY_COMMIT_SHA: __('Copy commit SHA'),
    MANUALLY_PUBLISHED: s__('PackageRegistry|Manually Published'),
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <template v-if="hasPipeline">
      <gl-icon name="merge-request" class="gl-mr-2" />
      <span data-testid="pipeline-ref" class="gl-mr-2">{{ pipeline.ref }}</span>

      <gl-icon name="commit" class="gl-mr-2" />
      <gl-link
        data-testid="pipeline-sha"
        :href="pipeline.commitPath"
        class="gl-mr-2 gl-underline"
        >{{ packageShaShort }}</gl-link
      >

      <clipboard-button
        :text="pipeline.sha"
        :title="$options.i18n.COPY_COMMIT_SHA"
        category="tertiary"
        size="small"
      />
    </template>

    <template v-else>
      <gl-icon name="upload" class="gl-mr-2" />
      <span data-testid="manually-published">
        {{ $options.i18n.MANUALLY_PUBLISHED }}
      </span>
    </template>
  </div>
</template>
