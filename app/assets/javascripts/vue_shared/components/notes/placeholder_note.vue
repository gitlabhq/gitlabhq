<script>
/**
 * Common component to render a placeholder note and user information.
 *
 * This component needs to be used with a vuex store.
 * That vuex store needs to have a `getUserData` getter that contains
 * {
 *   path: String,
 *   avatar_url: String,
 *   name: String,
 *   username: String,
 * }
 *
 * @example
 * <placeholder-note
 *   :note="{body: 'This is a note'}"
 *   />
 */
import { mapGetters } from 'vuex';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import userAvatarLink from '../user_avatar/user_avatar_link.vue';

export default {
  name: 'PlaceholderNote',
  components: {
    userAvatarLink,
    TimelineEntryItem,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getUserData']),
  },
};
</script>

<template>
  <timeline-entry-item class="note note-wrapper being-posted fade-in-half">
    <div class="timeline-icon">
      <user-avatar-link
        :link-href="getUserData.path"
        :img-src="getUserData.avatar_url"
        :img-size="40"
      />
    </div>
    <div ref="note" :class="{ discussion: !note.individual_note }" class="timeline-content">
      <div class="note-header">
        <div class="note-header-info">
          <a :href="getUserData.path">
            <span class="d-none d-sm-inline-block bold">{{ getUserData.name }}</span>
            <span class="note-headline-light">@{{ getUserData.username }}</span>
          </a>
        </div>
      </div>
      <div class="note-body">
        <div class="note-text md">
          <p>{{ note.body }}</p>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
