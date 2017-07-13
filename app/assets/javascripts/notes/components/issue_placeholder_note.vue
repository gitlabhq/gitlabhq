<script>
export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      currentUser: window.gl.currentUserData,
    };
  },
};
</script>

<template>
  <li class="note being-posted fade-in-half timeline-entry">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <a :href="currentUser.path">
          <img
            :src="currentUser.avatar_url"
            class="avatar s40" />
        </a>
      </div>
      <div
        :class="{ discussion: !note.individual_note }"
        class="timeline-content">
        <div class="note-header">
          <div class="note-header-info">
            <a :href="currentUser.path">
              <span class="hidden-xs">{{currentUser.name}}</span>
              <span class="note-headline-light">@{{currentUser.username}}</span>
            </a>
          </div>
        </div>
        <div class="note-body">
          <div class="note-text">
            <p>{{note.body}}</p>
          </div>
        </div>
      </div>
    </div>
  </li>
</template>
