<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlLink,
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { produce } from 'immer';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { __ } from '~/locale';
import { setUrlFragment } from '~/lib/utils/url_utility';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import EmojiPicker from '~/emoji/components/picker.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { TYPE_COMMENT } from '~/import/constants';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import updateNoteMutation from '../graphql/update_note.mutation.graphql';
import designNoteAwardEmojiToggleMutation from '../graphql/design_note_award_emoji_toggle.mutation.graphql';
import getDesignQuery from '../graphql/design_details.query.graphql';
import { findNoteId } from '../utils';
import { hasErrors } from '../cache_updates';
import { AWARD_EMOJI_TO_NOTE_ERROR } from '../constants';
import DesignReplyForm from './design_reply_form.vue';

export default {
  i18n: {
    editCommentLabel: __('Edit comment'),
    moreActionsLabel: __('More actions'),
    deleteCommentText: __('Delete comment'),
    copyCommentLink: __('Copy link'),
  },
  components: {
    AwardsList,
    GlAvatar,
    GlButton,
    GlAvatarLink,
    GlLink,
    GlDisclosureDropdown,
    ImportedBadge,
    TimeAgoTooltip,
    TimelineEntryItem,
    DesignReplyForm,
    EmojiPicker,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    designVariables: {
      type: Object,
      required: true,
    },
    isDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  computed: {
    mutationVariables() {
      return {
        id: this.note.id,
      };
    },
    author() {
      return this.note.author || {};
    },
    hasAuthor() {
      return !isEmpty(this.author);
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    noteAnchorId() {
      return findNoteId(this.note.id);
    },
    isImported() {
      return this.note.imported;
    },
    currentUserId() {
      return window.gon?.current_user_id;
    },
    currentUserFullName() {
      return window.gon?.current_user_fullname;
    },
    canAwardEmoji() {
      return this.note.userPermissions.awardEmoji;
    },
    adminPermissions() {
      return this.note.userPermissions.adminNote;
    },
    hasPermissions() {
      return this.adminPermissions;
    },
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
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.editCommentLabel,
          action: () => {
            this.isEditing = true;
          },
          extraAttrs: {
            class: 'sm:!gl-hidden',
          },
        },
        {
          text: this.$options.i18n.copyCommentLink,
          action: () => {
            this.$toast.show(__('Link copied to clipboard.'));
          },
          extraAttrs: {
            'data-clipboard-text': setUrlFragment(
              window.location.href,
              `note_${this.noteAnchorId}`,
            ),
          },
        },
        {
          text: this.$options.i18n.deleteCommentText,
          action: () => {
            this.$emit('delete-note', this.note);
          },
          extraAttrs: {
            class: ['!gl-text-red-500', { '!gl-hidden': !this.hasPermissions }],
          },
        },
      ];
    },
  },
  methods: {
    hideForm() {
      this.isEditing = false;
    },
    onDone({ data }) {
      this.hideForm();
      if (hasErrors(data.updateNote)) {
        this.$emit('error', data.errors[0]);
      }
    },
    isEmojiPresentForCurrentUser(name) {
      return (
        this.awards.findIndex(
          (emoji) => emoji.name === name && emoji.user.id === this.currentUserId,
        ) > -1
      );
    },
    /**
     * Prepare emoji reaction nodes based on emoji name
     * and whether the user has toggled the emoji off or on
     */
    getAwardEmojiNodes(name, toggledOn) {
      // If the emoji toggled on, add the emoji
      if (toggledOn) {
        // If emoji is already present in award list, no action is needed
        if (this.isEmojiPresentForCurrentUser(name)) {
          return this.note.awardEmoji.nodes;
        }

        // else return the list with new emoji added
        const newEmoji = {
          name,
          __typename: 'AwardEmoji',
          user: {
            id: convertToGraphQLId(TYPENAME_USER, this.currentUserId),
            name: this.currentUserFullName,
            __typename: 'UserCore',
          },
        };

        return [...this.note.awardEmoji.nodes, newEmoji];
      }

      // else just filter the emoji
      return this.note.awardEmoji.nodes.filter(
        (emoji) =>
          !(emoji.name === name && getIdFromGraphQLId(emoji.user.id) === this.currentUserId),
      );
    },
    async handleAwardEmoji(name) {
      try {
        await this.$apollo.mutate({
          mutation: designNoteAwardEmojiToggleMutation,
          variables: {
            name,
            awardableId: this.note.id,
          },
          optimisticResponse: {
            awardEmojiToggle: {
              errors: [],
              toggledOn: !this.isEmojiPresentForCurrentUser(name),
            },
          },
          update: (
            cache,
            {
              data: {
                awardEmojiToggle: { toggledOn },
              },
            },
          ) => {
            const query = {
              query: getDesignQuery,
              variables: this.designVariables,
            };
            const sourceData = cache.readQuery(query);

            const newData = produce(sourceData, (draftState) => {
              const { awardEmoji } =
                draftState.designManagement.designAtVersion.design.discussions.nodes
                  .find((d) => d.id === this.note.discussion.id)
                  .notes.nodes.find((n) => n.id === this.note.id);

              awardEmoji.nodes = this.getAwardEmojiNodes(name, toggledOn);
            });

            cache.writeQuery({ ...query, data: newData });
          },
        });
      } catch (error) {
        Sentry.captureException(error);
        this.$emit('error', AWARD_EMOJI_TO_NOTE_ERROR);
      }
    },
  },
  updateNoteMutation,
  TYPE_COMMENT,
};
</script>

<template>
  <timeline-entry-item :id="`note_${noteAnchorId}`" class="design-note note-form">
    <gl-avatar-link
      :href="author.webUrl"
      :data-user-id="authorId"
      :data-username="author.username"
      class="link-inherit-color js-user-link gl-float-left gl-mr-3"
    >
      <gl-avatar
        :size="32"
        :src="author.avatarUrl"
        :entity-name="author.username"
        :alt="author.username"
      />
    </gl-avatar-link>

    <div class="gl-flex gl-justify-between">
      <div class="gl-my-[6px]">
        <gl-link
          v-if="hasAuthor"
          v-once
          :href="author.webUrl"
          class="js-user-link link-inherit-color"
          data-testid="user-link"
          :data-user-id="authorId"
          :data-username="author.username"
        >
          <span class="note-header-author-name gl-font-bold">{{ author.name }}</span>
          <span v-if="author.status_tooltip_html" v-safe-html="author.status_tooltip_html"></span>
          <span class="note-headline-light">@{{ author.username }}</span>
        </gl-link>
        <span v-else>{{ __('A deleted user') }}</span>
        <span class="note-headline-light note-headline-meta">
          <span class="system-note-message"> <slot></slot> </span>
          <gl-link
            class="note-timestamp system-note-separator link-inherit-color gl-inline-block gl-text-sm"
            :href="`#note_${noteAnchorId}`"
          >
            <time-ago-tooltip :time="note.createdAt" tooltip-placement="bottom" />
          </gl-link>
          <imported-badge v-if="isImported" :importable-type="$options.TYPE_COMMENT" size="sm" />
        </span>
      </div>
      <div class="gl-flex gl-items-start">
        <slot name="resolve-discussion"></slot>
        <emoji-picker
          v-if="canAwardEmoji"
          toggle-class="add-reaction-button btn-default-tertiary"
          :right="false"
          data-testid="note-emoji-button"
          @click="handleAwardEmoji"
        />
        <gl-button
          v-if="!isEditing && hasPermissions"
          v-gl-tooltip
          class="gl-hidden sm:!gl-flex"
          :aria-label="$options.i18n.editCommentLabel"
          :title="$options.i18n.editCommentLabel"
          category="tertiary"
          data-testid="note-edit"
          icon="pencil"
          @click="isEditing = true"
        />
        <gl-disclosure-dropdown
          v-if="!isEditing"
          v-gl-tooltip
          icon="ellipsis_v"
          category="tertiary"
          text-sr-only
          :title="$options.i18n.moreActionsLabel"
          :aria-label="$options.i18n.moreActionsLabel"
          no-caret
          left
          :items="dropdownItems"
          data-testid="more-actions"
        />
      </div>
    </div>
    <template v-if="!isEditing">
      <div v-safe-html="note.bodyHtml" class="note-text md" data-testid="note-text"></div>
      <slot name="resolved-status"></slot>
    </template>
    <awards-list
      v-if="awards.length"
      :awards="awards"
      :can-award-emoji="note.userPermissions.awardEmoji"
      :current-user-id="currentUserId"
      class="gl-mt-5 gl-px-2"
      @award="handleAwardEmoji"
    />
    <design-reply-form
      v-if="isEditing"
      :markdown-preview-path="markdownPreviewPath"
      :design-note-mutation="$options.updateNoteMutation"
      :mutation-variables="mutationVariables"
      :value="note.body"
      :is-new-comment="false"
      :is-discussion="isDiscussion"
      :noteable-id="noteableId"
      class="gl-mt-5"
      @note-submit-complete="onDone"
      @cancel-form="hideForm"
    />
  </timeline-entry-item>
</template>
