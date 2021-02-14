<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { uniqBy } from 'lodash';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    UserAvatarLink,
    TimeAgoTooltip,
  },
  props: {
    collapsed: {
      type: Boolean,
      required: true,
    },
    replies: {
      type: Array,
      required: true,
    },
  },
  computed: {
    lastReply() {
      return this.replies[this.replies.length - 1];
    },
    uniqueAuthors() {
      const authors = this.replies.map((reply) => reply.author || {});

      return uniqBy(authors, (author) => author.username);
    },
    className() {
      return this.collapsed ? 'collapsed' : 'expanded';
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
  ICON_CLASS: 'gl-mr-3 gl-cursor-pointer',
};
</script>

<template>
  <li
    :class="className"
    class="replies-toggle js-toggle-replies gl-display-flex! gl-align-items-center gl-flex-wrap"
  >
    <template v-if="collapsed">
      <gl-icon :class="$options.ICON_CLASS" name="chevron-right" @click.native="toggle" />
      <div>
        <user-avatar-link
          v-for="author in uniqueAuthors"
          :key="author.username"
          :link-href="author.path"
          :img-alt="author.name"
          :img-src="author.avatar_url"
          :img-size="26"
          :tooltip-text="author.name"
          tooltip-placement="bottom"
        />
      </div>
      <gl-button
        class="js-replies-text gl-mr-2"
        category="tertiary"
        variant="link"
        data-qa-selector="expand_replies_button"
        @click="toggle"
      >
        {{ replies.length }} {{ n__('reply', 'replies', replies.length) }}
      </gl-button>
      {{ __('Last reply by') }}
      <a :href="lastReply.author.path" class="btn btn-link author-link gl-mx-2">
        {{ lastReply.author.name }}
      </a>
      <time-ago-tooltip :time="lastReply.created_at" tooltip-placement="bottom" />
    </template>
    <div
      v-else
      class="collapse-replies-btn js-collapse-replies gl-display-flex align-items-center"
      data-qa-selector="collapse_replies_button"
      @click="toggle"
    >
      <gl-icon :class="$options.ICON_CLASS" name="chevron-down" />
      <span class="gl-cursor-pointer">{{ s__('Notes|Collapse replies') }}</span>
    </div>
  </li>
</template>
