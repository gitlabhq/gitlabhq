<script>
/**
 * This component displays topic badges for projects and catalog resources.
 */
import { GlBadge, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';

const MAX_TOPICS_TO_SHOW = 3;
const MAX_TOPIC_TITLE_LENGTH = 15;

export default {
  name: 'TopicBadges',
  i18n: {
    topics: s__('Topics|Topics'),
    topicsPopoverTargetText: s__('Topics|+%{count} more'),
    moreTopics: s__('Topics|More topics'),
  },
  components: {
    GlBadge,
    GlPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    showLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
    topics: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      topicsPopoverTarget: uniqueId('project-topics-popover-'),
    };
  },
  computed: {
    visibleTopics() {
      return this.topics.slice(0, MAX_TOPICS_TO_SHOW);
    },
    collapsedTopics() {
      return this.topics.slice(MAX_TOPICS_TO_SHOW);
    },
    popoverText() {
      return sprintf(s__('Topics|+%{count} more'), {
        count: this.collapsedTopics.length,
      });
    },
  },
  methods: {
    topicPath(topic) {
      const explorePath = `/explore/projects/topics/${encodeURIComponent(topic)}`;

      return joinPaths(gon.relative_url_root || '', explorePath);
    },
    topicTitle(topic) {
      return truncate(topic, MAX_TOPIC_TITLE_LENGTH);
    },
    topicTooltipTitle(topic) {
      const wasTruncated = topic !== this.topicTitle(topic);
      if (wasTruncated) {
        return topic;
      }

      return null;
    },
  },
};
</script>

<template>
  <div
    v-if="topics.length"
    class="gl-inline-flex gl-flex-wrap gl-items-center gl-gap-3 gl-text-sm gl-text-subtle"
  >
    <span v-if="showLabel">{{ $options.i18n.topics }}:</span>
    <div v-for="topic in visibleTopics" :key="topic">
      <gl-badge v-gl-tooltip="topicTooltipTitle(topic)" :href="topicPath(topic)">
        {{ topicTitle(topic) }}
      </gl-badge>
    </div>
    <template v-if="collapsedTopics.length">
      <div :id="topicsPopoverTarget" role="button" tabindex="0" data-testid="more-topics-label">
        {{ popoverText }}
      </div>
      <gl-popover :target="topicsPopoverTarget" :title="$options.i18n.moreTopics">
        <div class="gl-flex gl-flex-wrap gl-gap-3">
          <gl-badge
            v-for="topic in collapsedTopics"
            :key="topic"
            v-gl-tooltip="topicTooltipTitle(topic)"
            :href="topicPath(topic)"
          >
            {{ topicTitle(topic) }}
          </gl-badge>
        </div>
      </gl-popover>
    </template>
  </div>
</template>
