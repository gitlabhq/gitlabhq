<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlButton,
  GlDisclosureDropdown,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import updateNoteMutation from '../../graphql/mutations/update_note.mutation.graphql';
import { hasErrors } from '../../utils/cache_update';
import { findNoteId, extractDesignNoteId } from '../../utils/design_management_utils';
import DesignReplyForm from './design_reply_form.vue';

export default {
  i18n: {
    editCommentLabel: __('Edit comment'),
    moreActionsLabel: __('More actions'),
    deleteCommentText: __('Delete comment'),
  },
  components: {
    DesignReplyForm,
    GlAvatar,
    GlAvatarLink,
    GlButton,
    GlDisclosureDropdown,
    GlLink,
    TimeAgoTooltip,
    TimelineEntryItem,
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
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    isDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteableId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      isError: true,
    };
  },
  computed: {
    author() {
      return this.note.author;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    noteAnchorId() {
      return findNoteId(this.note.id);
    },
    isNoteLinked() {
      return extractDesignNoteId(this.$route.hash) === this.noteAnchorId;
    },
    mutationVariables() {
      return {
        id: this.note.id,
      };
    },
    isEditingAndHasPermissions() {
      return !this.isEditing && this.adminPermissions;
    },
    adminPermissions() {
      return this.note.userPermissions.adminNote;
    },
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.editCommentLabel,
          action: () => {
            this.isEditing = true;
          },
          extraAttrs: {
            'data-testid': 'delete-note-button',
            'data-qa-selector': 'delete_design_note_button',
            class: 'gl-sm-display-none!',
          },
        },
        {
          text: this.$options.i18n.deleteCommentText,
          action: () => {
            this.$emit('delete-note', this.note);
          },
          extraAttrs: {
            'data-testid': 'delete-note-button',
            'data-qa-selector': 'delete_design_note_button',
            class: 'gl-text-red-500!',
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
  },
  updateNoteMutation,
};
</script>

<template>
  <timeline-entry-item :id="`note_${noteAnchorId}`" class="design-note note-form">
    <gl-avatar-link :href="author.webUrl" class="gl-float-left gl-mr-3 link-inherit-color">
      <gl-avatar :size="32" :src="author.avatarUrl" :entity-name="author.username" />
    </gl-avatar-link>

    <div class="gl-display-flex gl-justify-content-space-between">
      <div>
        <gl-link
          v-once
          :href="author.webUrl"
          class="js-user-link link-inherit-color"
          data-testid="user-link"
          :data-user-id="authorId"
          :data-username="author.username"
        >
          <span class="note-header-author-name gl-font-weight-bold">{{ author.name }}</span>
          <span v-if="author.status_tooltip_html" v-safe-html="author.status_tooltip_html"></span>
          <span class="note-headline-light">@{{ author.username }}</span>
        </gl-link>
        <span class="note-headline-light note-headline-meta">
          <span class="system-note-message"> <slot></slot> </span>
          <gl-link
            class="note-timestamp system-note-separator gl-display-block gl-mb-2 gl-font-sm link-inherit-color"
            :href="`#note_${noteAnchorId}`"
          >
            <time-ago-tooltip :time="note.createdAt" tooltip-placement="bottom" />
          </gl-link>
        </span>
      </div>
      <div class="gl-display-flex gl-align-items-baseline gl-mt-n2 gl-mr-n2">
        <slot name="resolve-discussion"></slot>
        <gl-button
          v-if="isEditingAndHasPermissions"
          v-gl-tooltip
          class="gl-display-none gl-sm-display-inline-flex!"
          :aria-label="$options.i18n.editCommentLabel"
          :title="$options.i18n.editCommentLabel"
          category="tertiary"
          data-testid="note-edit"
          icon="pencil"
          @click="isEditing = true"
        />
        <gl-disclosure-dropdown
          v-if="isEditingAndHasPermissions"
          v-gl-tooltip.hover
          icon="ellipsis_v"
          category="tertiary"
          data-qa-selector="design_discussion_actions_ellipsis_dropdown"
          data-testid="more-actions-dropdown"
          text-sr-only
          :title="$options.i18n.moreActionsLabel"
          :aria-label="$options.i18n.moreActionsLabel"
          no-caret
          left
          :items="dropdownItems"
        />
      </div>
    </div>
    <template v-if="!isEditing">
      <div
        v-safe-html="note.bodyHtml"
        class="note-text md"
        data-qa-selector="note_content"
        data-testid="note-text"
      ></div>
      <slot name="resolved-status"></slot>
    </template>
    <design-reply-form
      v-else
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
