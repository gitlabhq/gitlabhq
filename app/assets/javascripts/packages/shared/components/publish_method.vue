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
  <div class="d-flex align-items-center order-1 order-md-0 mb-md-1">
    <template v-if="hasPipeline">
      <gl-icon name="git-merge" class="mr-1" />
      <span ref="pipeline-ref" class="mr-1">{{ packageEntity.pipeline.ref }}</span>

      <gl-icon name="commit" class="mr-1" />
      <gl-link ref="pipeline-sha" :href="linkToCommit" class="mr-1">{{ packageShaShort }}</gl-link>

      <clipboard-button
        :text="packageEntity.pipeline.sha"
        :title="__('Copy commit SHA')"
        css-class="border-0 py-0 px-1"
      />
    </template>

    <template v-else>
      <gl-icon name="upload" class="mr-1" />
      <span ref="manual-ref">{{ s__('PackageRegistry|Manually Published') }}</span>
    </template>
  </div>
</template>
