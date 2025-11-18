<script>
import { GlBadge, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

export default {
  name: 'CommitBadges',
  components: {
    GlBadge,
    GlTruncate,
    SignatureBadge,
    CiIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-my-2 gl-flex gl-flex-wrap gl-items-center gl-gap-3 @md/panel:gl-hidden"
      data-testid="commit-badges-mobile-container"
    >
      <div v-if="commit.pipelines.edges.length" class="gl-flex gl-items-center">
        <ci-icon :status="commit.pipelines.edges[0].node.detailedStatus" />
      </div>
      <signature-badge
        v-if="commit.signature"
        :signature="commit.signature"
        class="gl-my-2 !gl-ml-0 gl-h-6"
      />
      <gl-badge v-if="commit.tag" icon="tag" variant="neutral" class="gl-h-6 gl-max-w-15">
        <gl-truncate :text="commit.tag.name" with-tooltip />
      </gl-badge>
      <span class="gl-font-monospace" data-testid="commit-sha">
        {{ commit.shortId }}
      </span>
    </div>
    <div
      class="gl-hidden gl-items-center gl-gap-3 @md/panel:gl-flex"
      data-testid="commit-badges-container"
    >
      <gl-badge v-if="commit.tag" icon="tag" variant="neutral" class="gl-h-6">{{
        commit.tag.name
      }}</gl-badge>
      <signature-badge
        v-if="commit.signature"
        :signature="commit.signature"
        class="gl-my-2 !gl-ml-0 gl-h-6"
      />
      <div v-if="commit.pipelines.edges.length" class="gl-flex gl-items-center">
        <ci-icon :status="commit.pipelines.edges[0].node.detailedStatus" />
      </div>
    </div>
  </div>
</template>
