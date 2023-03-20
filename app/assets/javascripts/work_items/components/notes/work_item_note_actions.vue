<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __, s__ } from '~/locale';
import ReplyButton from '~/notes/components/note_actions/reply_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import addAwardEmojiMutation from '../../graphql/notes/work_item_note_add_award_emoji.mutation.graphql';

export default {
  name: 'WorkItemNoteActions',
  i18n: {
    editButtonText: __('Edit comment'),
  },
  components: {
    GlButton,
    GlIcon,
    ReplyButton,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    showReply: {
      type: Boolean,
      required: true,
    },
    showEdit: {
      type: Boolean,
      required: true,
    },
    noteId: {
      type: String,
      required: true,
    },
    showAwardEmoji: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    async setAwardEmoji(name) {
      try {
        const {
          data: {
            awardEmojiAdd: { errors = [] },
          },
        } = await this.$apollo.mutate({
          mutation: addAwardEmojiMutation,
          variables: {
            awardableId: this.noteId,
            name,
          },
        });

        if (errors.length > 0) {
          throw new Error(errors[0].message);
        }
      } catch (error) {
        this.$emit('error', s__('WorkItem|Failed to award emoji'));
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <div class="note-actions">
    <emoji-picker
      v-if="showAwardEmoji && glFeatures.workItemsMvc2"
      toggle-class="note-action-button note-emoji-button btn-icon btn-default-tertiary"
      data-testid="note-emoji-button"
      @click="setAwardEmoji"
    >
      <template #button-content>
        <gl-icon class="award-control-icon-neutral gl-button-icon gl-icon" name="slight-smile" />
        <gl-icon
          class="award-control-icon-positive gl-button-icon gl-icon gl-left-3!"
          name="smiley"
        />
        <gl-icon
          class="award-control-icon-super-positive gl-button-icon gl-icon gl-left-3!"
          name="smile"
        />
      </template>
    </emoji-picker>
    <reply-button v-if="showReply" ref="replyButton" @startReplying="$emit('startReplying')" />
    <gl-button
      v-if="showEdit"
      v-gl-tooltip
      data-testid="edit-work-item-note"
      data-track-action="click_button"
      data-track-label="edit_button"
      category="tertiary"
      icon="pencil"
      :title="$options.i18n.editButtonText"
      :aria-label="$options.i18n.editButtonText"
      @click="$emit('startEditing')"
    />
  </div>
</template>
