<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { getCommitLink } from '../utils';

export default {
  name: 'PublishMethod',
  components: {
    ClipboardButton,
    GlIcon,
    GlLink,
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasPipeline() {
      return Boolean(this.packageEntity.pipeline);
    },
    packageShaShort() {
      return this.packageEntity.pipeline?.sha.substring(0, 8);
    },
    linkToCommit() {
      return getCommitLink(this.packageEntity, this.isGroup);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <template v-if="hasPipeline">
      <gl-icon name="merge-request" class="gl-mr-2" />
      <span data-testid="pipeline-ref" class="gl-mr-2">{{ packageEntity.pipeline.ref }}</span>

      <gl-icon name="commit" class="gl-mr-2" />
      <gl-link data-testid="pipeline-sha" :href="linkToCommit" class="gl-mr-2">{{
        packageShaShort
      }}</gl-link>

      <clipboard-button
        :text="packageEntity.pipeline.sha"
        :title="__('Copy commit SHA')"
        category="tertiary"
        size="small"
      />
    </template>

    <template v-else>
      <gl-icon name="upload" class="gl-mr-2" />
      <span data-testid="manually-published">
        {{ s__('PackageRegistry|Manually Published') }}
      </span>
    </template>
  </div>
</template>
