<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import AwardsList from '~/vue_shared/components/awards_list.vue';

export default {
  components: {
    AwardsList,
  },
  props: {
    awards: {
      type: Array,
      required: true,
    },
    toggleAwardPath: {
      type: String,
      required: true,
    },
    noteAuthorId: {
      type: Number,
      required: true,
    },
    noteId: {
      type: String,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getUserData']),
    isAuthoredByMe() {
      return this.noteAuthorId === this.getUserData.id;
    },
  },
  methods: {
    ...mapActions(['toggleAwardRequest']),
    handleAward(awardName) {
      const data = {
        endpoint: this.toggleAwardPath,
        noteId: this.noteId,
        awardName,
      };

      this.toggleAwardRequest(data).catch(() =>
        createAlert({
          message: __('Something went wrong on our end.'),
        }),
      );
    },
  },
};
</script>

<template>
  <div class="note-awards">
    <awards-list
      :awards="awards"
      :can-award-emoji="canAwardEmoji"
      :current-user-id="getUserData.id"
      @award="handleAward($event)"
    />
  </div>
</template>
