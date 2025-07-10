<script>
import { GlLink, GlAvatar, GlAvatarLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  TODO_ACTION_TYPE_ADDED_APPROVER,
  TODO_ACTION_TYPE_APPROVAL_REQUIRED,
  TODO_ACTION_TYPE_ASSIGNED,
  TODO_ACTION_TYPE_BUILD_FAILED,
  TODO_ACTION_TYPE_DIRECTLY_ADDRESSED,
  TODO_ACTION_TYPE_MARKED,
  TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED,
  TODO_ACTION_TYPE_MENTIONED,
  TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED,
  TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_REQUESTED,
  TODO_ACTION_TYPE_REVIEW_SUBMITTED,
  TODO_ACTION_TYPE_UNMERGEABLE,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRED,
  TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON,
  DUO_ACCESS_GRANTED_ACTIONS,
} from '../constants';
import TodoItemTitle from './todo_item_title.vue';
import TodoItemTitleHiddenBySaml from './todo_item_title_hidden_by_saml.vue';

export default {
  components: {
    GlLink,
    GlAvatar,
    GlAvatarLink,
  },
  directives: {
    SafeHtml,
  },
  inject: ['currentUserId'],
  props: {
    todo: {
      type: Object,
      required: true,
    },
    isHiddenBySaml: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    noteText() {
      if (!this.todo.note) {
        return null;
      }
      return this.todo.note.bodyFirstLineHtml.replace(/(<\/?)p>/g, '$1span>');
    },
    showAuthorOnNote() {
      return (
        this.todo.action !== TODO_ACTION_TYPE_BUILD_FAILED &&
        this.todo.action !== TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED &&
        this.todo.action !== TODO_ACTION_TYPE_UNMERGEABLE &&
        this.todo.action !== TODO_ACTION_TYPE_SSH_KEY_EXPIRED &&
        this.todo.action !== TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON &&
        !DUO_ACCESS_GRANTED_ACTIONS.includes(this.todo.action)
      );
    },
    showAvatarOnNote() {
      // do not show avatar on duo todo's which were authored by the user
      return (
        !DUO_ACCESS_GRANTED_ACTIONS.includes(this.todo.action) ||
        this.todo.author.id !== this.currentUserId
      );
    },
    titleComponent() {
      return this.isHiddenBySaml ? TodoItemTitleHiddenBySaml : TodoItemTitle;
    },
    author() {
      if (this.isHiddenBySaml) {
        return {
          name: s__('Todos|Someone'),
          webUrl: this.todo.targetUrl,
          avatarUrl: gon.default_avatar_url,
        };
      }
      return this.todo.author;
    },
    userIsAuthor() {
      return this.author.id === this.currentUserId;
    },
    authorOnNote() {
      return this.userIsAuthor ? s__('Todos|You') : this.author.name;
    },
    actionSubject() {
      return this.userIsAuthor && !this.isHiddenBySaml ? s__('Todos|yourself') : s__('Todos|you');
    },
    actionName() {
      if (this.todo.note) {
        return null;
      }

      let name = '';

      if (this.todo.action === TODO_ACTION_TYPE_ASSIGNED) {
        name = this.userIsAuthor ? s__('Todos|assigned to yourself') : s__('Todos|assigned you');
      }

      if (this.todo.action === TODO_ACTION_TYPE_REVIEW_REQUESTED) {
        name = this.userIsAuthor
          ? s__('Todos|requested a review from yourself')
          : s__('Todos|requested a review');
      }

      if (
        this.todo.action === TODO_ACTION_TYPE_MENTIONED ||
        this.todo.action === TODO_ACTION_TYPE_DIRECTLY_ADDRESSED
      ) {
        name = sprintf(s__('Todos|mentioned %{who}'), { who: this.actionSubject });
      }

      if (this.todo.action === TODO_ACTION_TYPE_BUILD_FAILED) {
        name = s__('Todos|The pipeline failed');
      }

      if (this.todo.action === TODO_ACTION_TYPE_MARKED) {
        name = s__('Todos|added a to-do item');
      }

      if (
        this.todo.action === TODO_ACTION_TYPE_APPROVAL_REQUIRED ||
        this.todo.action === TODO_ACTION_TYPE_ADDED_APPROVER
      ) {
        name = s__('Todos|created a merge request you can approve');
      }

      if (this.todo.action === TODO_ACTION_TYPE_UNMERGEABLE) {
        name = s__('Todos|Could not merge');
      }

      if (this.todo.action === TODO_ACTION_TYPE_MERGE_TRAIN_REMOVED) {
        name = s__('Todos|Removed from Merge Train');
      }

      if (this.todo.action === TODO_ACTION_TYPE_MEMBER_ACCESS_REQUESTED) {
        name = sprintf(s__('Todos|has requested access to %{what} %{which}'), {
          what: this.todo.memberAccessType,
          which: this.todo.targetEntity.name,
        });
      }

      if (this.todo.action === TODO_ACTION_TYPE_REVIEW_SUBMITTED) {
        name = s__('Todos|reviewed your merge request');
      }

      if (this.todo.action === TODO_ACTION_TYPE_OKR_CHECKIN_REQUESTED) {
        name = sprintf(s__('Todos|requested an OKR update for %{which}'), {
          which: this.todo.targetEntity.name,
        });
      }

      if (this.todo.action === TODO_ACTION_TYPE_SSH_KEY_EXPIRED) {
        name = s__('Todos|Your SSH key has expired');
      }

      if (this.todo.action === TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON) {
        name = s__('Todos|Your SSH key is expiring soon');
      }

      if (DUO_ACCESS_GRANTED_ACTIONS.includes(this.todo.action)) {
        name = this.todo.body;
      }

      if (!name) {
        Sentry.captureException(
          new Error(`Encountered unknown TODO_ACTION_TYPE ${this.todo.action}`),
        );
        return null;
      }

      return `${name}.`;
    },
  },
  i18n: {
    removed: s__('Todos|(removed)'),
  },
};
</script>

<template>
  <div class="gl-flex gl-min-w-0 gl-gap-3" data-testid="todo-item-container">
    <div v-if="showAvatarOnNote" class="gl-hidden sm:gl-inline-block">
      <gl-avatar-link :href="author.webUrl" aria-hidden="true" tabindex="-1" class="gl-mt-1">
        <gl-avatar :size="32" :src="author.avatarUrl" role="none" />
      </gl-avatar-link>
    </div>

    <div class="gl-flex gl-min-w-0 gl-flex-col gl-gap-1">
      <component
        :is="titleComponent"
        :todo="todo"
        class="gl-flex gl-min-w-0 gl-items-center gl-gap-1 gl-overflow-hidden gl-whitespace-nowrap gl-text-sm gl-text-subtle"
      />

      <div>
        <div v-if="showAuthorOnNote" class="gl-inline-flex gl-font-bold">
          <gl-link
            v-if="author"
            :href="author.webUrl"
            class="!gl-text-default"
            data-testid="todo-author-name-content"
            >{{ authorOnNote }}</gl-link
          >
          <span v-else>{{ $options.i18n.removed }}</span>
          <span v-if="todo.note">:</span>
        </div>
        <span v-if="actionName" data-testid="todo-action-name-content">
          {{ actionName }}
        </span>
        <span v-if="noteText" v-safe-html="noteText"></span>
      </div>
    </div>
  </div>
</template>
