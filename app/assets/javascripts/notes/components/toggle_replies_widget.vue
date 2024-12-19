<script>
import { GlButton, GlLink, GlSprintf, GlAvatarLink, GlAvatar, GlAvatarsInline } from '@gitlab/ui';
import { uniqBy } from 'lodash';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  i18n: {
    collapseReplies: s__('Notes|Collapse replies'),
    expandReplies: s__('Notes|Expand replies'),
    lastReplyBy: s__('Notes|Last reply by %{name}'),
  },
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    GlAvatarLink,
    GlAvatar,
    GlAvatarsInline,
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

      return uniqBy(authors, 'username');
    },
    buttonIcon() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    buttonLabel() {
      return this.collapsed ? this.$options.i18n.expandReplies : this.$options.i18n.collapseReplies;
    },
    ariaState() {
      return String(!this.collapsed);
    },
  },
  methods: {
    toggle() {
      this.$refs.toggle.$el.focus();
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <li
    :class="{ '!gl-rounded-b-base gl-text-subtle': collapsed }"
    class="toggle-replies-widget gl-border-r gl-border-l !gl-flex gl-flex-wrap gl-items-center gl-border-l-section gl-border-r-section gl-bg-subtle gl-px-5 gl-py-2 gl-leading-24"
    :aria-expanded="ariaState"
  >
    <gl-button
      ref="toggle"
      class="gl-my-2 -gl-ml-3 gl-mr-2 !gl-p-0"
      :class="{ '!gl-text-link': !collapsed }"
      category="tertiary"
      :icon="buttonIcon"
      :aria-label="buttonLabel"
      data-testid="replies-toggle"
      size="small"
      @click="toggle"
    />
    <template v-if="collapsed">
      <gl-avatars-inline
        :avatars="uniqueAuthors"
        :avatar-size="24"
        :max-visible="5"
        badge-sr-only-text=""
        class="gl-mr-3"
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link
            target="_blank"
            :href="avatar.path || avatar.webUrl"
            :data-user-id="avatar.id"
            :data-username="avatar.username"
            class="js-user-link"
          >
            <gl-avatar :size="24" :src="avatar.avatar_url || avatar.avatarUrl" :alt="avatar.name" />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>
      <gl-button
        class="gl-mr-2 gl-self-center"
        variant="link"
        data-testid="expand-replies-button"
        @click="toggle"
      >
        {{ n__('%d reply', '%d replies', replies.length) }}
      </gl-button>
      <gl-sprintf :message="$options.i18n.lastReplyBy">
        <template #name>
          <gl-link
            :href="lastReply.author.path || lastReply.author.webUrl"
            class="gl-mx-2 !gl-text-default !gl-no-underline"
          >
            {{ lastReply.author.name }}
          </gl-link>
        </template>
      </gl-sprintf>
      <time-ago-tooltip
        :time="lastReply.created_at || lastReply.createdAt"
        tooltip-placement="bottom"
      />
    </template>
    <gl-button
      v-else
      class="!gl-no-underline"
      variant="link"
      data-testid="collapse-replies-button"
      @click="toggle"
    >
      {{ $options.i18n.collapseReplies }}
    </gl-button>
  </li>
</template>
