<script>
import { GlBadge, GlTooltipDirective, GlTruncate } from '@gitlab/ui';
import AgentSessionBadge from '~/commit/components/agent_session_badge.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

export default {
  name: 'CommitBadges',
  components: {
    GlBadge,
    GlTruncate,
    AgentSessionBadge,
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
  computed: {
    commitTags() {
      return this.commit.tags || [];
    },
    hasSingleTag() {
      return this.commit.tags?.length === 1;
    },
    hasMultipleTags() {
      return this.commit.tags?.length > 1;
    },
    hasPipeline() {
      return this.commit.pipelines?.edges?.length > 0;
    },
    pipelineStatus() {
      return this.commit.pipelines?.edges?.[0]?.node?.detailedStatus;
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
      <code class="gl-font-monospace" data-testid="commit-sha">
        {{ commit.shortId }}
      </code>
      <div v-if="hasPipeline" class="gl-flex gl-items-center">
        <ci-icon :status="pipelineStatus" />
      </div>
      <signature-badge
        v-if="commit.signature"
        :signature="commit.signature"
        class="gl-my-2 !gl-ml-0 gl-h-6"
      />
      <agent-session-badge v-if="commit.hasAgentSession" />
      <button
        v-if="hasMultipleTags"
        v-gl-tooltip
        class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0"
        :aria-label="commitTags.join(', ')"
        :title="commitTags.join(', ')"
      >
        <gl-badge icon="tag" class="gl-h-6 gl-max-w-15">
          {{ n__('1 tag', '%d tags', commitTags.length) }}
        </gl-badge>
      </button>
      <button
        v-else-if="hasSingleTag"
        class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0"
        :aria-label="commitTags[0]"
      >
        <gl-badge icon="tag" class="gl-h-6 gl-max-w-15">
          <gl-truncate :text="commitTags[0]" with-tooltip />
        </gl-badge>
      </button>
    </div>

    <div
      class="gl-hidden gl-items-center gl-gap-3 @md/panel:gl-flex"
      data-testid="commit-badges-container"
    >
      <agent-session-badge v-if="commit.hasAgentSession" />
      <button
        v-if="hasMultipleTags"
        v-gl-tooltip
        class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0"
        :aria-label="commitTags.join(', ')"
        :title="commitTags.join(', ')"
      >
        <gl-badge icon="tag" class="gl-h-6">
          {{ n__('1 tag', '%d tags', commitTags.length) }}
        </gl-badge>
      </button>
      <button
        v-else-if="hasSingleTag"
        class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0"
        :aria-label="commitTags[0]"
      >
        <gl-badge icon="tag" class="gl-h-6">
          <gl-truncate :text="commitTags[0]" with-tooltip />
        </gl-badge>
      </button>
      <signature-badge
        v-if="commit.signature"
        :signature="commit.signature"
        class="gl-my-2 !gl-ml-0 gl-h-6"
      />
      <div v-if="hasPipeline" class="gl-flex gl-items-center">
        <ci-icon :status="pipelineStatus" />
      </div>
    </div>
  </div>
</template>
