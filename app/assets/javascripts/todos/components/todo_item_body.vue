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
} from '../constants';

export default {
  components: {
    GlLink,
    GlAvatar,
    GlAvatarLink,
  },
  directives: {
    SafeHtml,
  },
  props: {
    currentUserId: {
      type: String,
      required: true,
    },
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
        this.todo.action !== TODO_ACTION_TYPE_SSH_KEY_EXPIRING_SOON
      );
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
        name = sprintf(s__('Todos|set %{who} as an approver'), { who: this.actionSubject });
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
  <div class="gl-flex gl-items-start gl-px-2" data-testid="todo-item-container">
    <div class="gl-mr-3 gl-hidden sm:gl-inline-block">
      <gl-avatar-link :href="author.webUrl" aria-hidden="true" tabindex="-1">
        <gl-avatar :size="24" :src="author.avatarUrl" role="none" />
      </gl-avatar-link>
    </div>
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

      <!-- TODO: AI? Review summary here: https://gitlab.com/gitlab-org/gitlab/-/work_items/483061 -->
    </div>
  </div>
</template>
