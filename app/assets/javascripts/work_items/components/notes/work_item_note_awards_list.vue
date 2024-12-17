<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { getMutation, optimisticAwardUpdate } from '../../notes/award_utils';

export default {
  components: {
    AwardsList,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    note: {
      type: Object,
      required: true,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    awards() {
      return this.note.awardEmoji.nodes.map((award) => {
        return {
          ...award,
          user: {
            ...award.user,
            id: getIdFromGraphQLId(award.user.id),
          },
        };
      });
    },
    hasAwardEmojiPermission() {
      return this.note.userPermissions.awardEmoji;
    },
    currentUserId() {
      return window.gon.current_user_id;
    },
  },
  methods: {
    async handleAward(name) {
      if (!this.hasAwardEmojiPermission) {
        return;
      }

      const { mutation, mutationName, errorMessage } = getMutation({ note: this.note, name });

      try {
        await this.$apollo.mutate({
          mutation,
          variables: {
            awardableId: this.note.id,
            name,
          },
          optimisticResponse: {
            [mutationName]: {
              errors: [],
            },
          },
          update: optimisticAwardUpdate({
            note: this.note,
            name,
            fullPath: this.fullPath,
            workItemIid: this.workItemIid,
          }),
        });
      } catch (error) {
        this.$emit('error', errorMessage);
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <awards-list
    v-if="awards.length"
    :awards="awards"
    :can-award-emoji="hasAwardEmojiPermission"
    :current-user-id="currentUserId"
    @award="handleAward($event)"
  />
</template>
