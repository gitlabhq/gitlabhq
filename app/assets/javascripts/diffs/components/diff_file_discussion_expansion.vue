<script>
import { GlAvatarLink, GlAvatar, GlAvatarsInline, GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlAvatarLink,
    GlAvatar,
    GlAvatarsInline,
    GlButton,
    GlSprintf,
    GlLink,
    TimeAgoTooltip,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    avatars() {
      return this.discussions.reduce((acc, discussion) => {
        acc.push(discussion.notes[0].author);

        return acc;
      }, []);
    },
    lastNote() {
      return this.discussions.at(-1).notes.at(-1);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-bg-subtle gl-py-3 gl-px-5 gl-border-b">
    <gl-avatars-inline :avatars="avatars" :avatar-size="24" :max-visible="5" badge-sr-only-text="">
      <template #avatar="{ avatar }">
        <gl-avatar-link
          target="_blank"
          :href="avatar.path"
          :data-user-id="avatar.id"
          :data-username="avatar.username"
          class="js-user-link"
        >
          <gl-avatar :size="24" :src="avatar.avatar_url" :alt="avatar.name" />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
    <div class="gl-ml-3">
      <gl-button
        variant="link"
        class="gl-align-baseline"
        data-testid="toggle-btn"
        @click="$emit('toggle')"
      >
        {{ n__('%d comment', '%d comments', discussions.length) }}
      </gl-button>
      <span class="gl-text-secondary">
        <gl-sprintf :message="__('Last comment by %{author} %{timeago}')">
          <template #author>
            <gl-link
              :href="lastNote.author.path"
              class="gl-text-body author-link js-user-link"
              :data-user-id="lastNote.author.id"
              :data-username="lastNote.author.username"
            >
              {{ lastNote.author.name }}
            </gl-link>
          </template>
          <template #timeago>
            <time-ago-tooltip :time="lastNote.created_at" tooltip-placement="bottom" />
          </template>
        </gl-sprintf>
      </span>
    </div>
  </div>
</template>
