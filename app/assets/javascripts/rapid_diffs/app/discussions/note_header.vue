<script>
import { GlBadge, GlLoadingIcon, GlTooltipDirective, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'NoteHeader',
  components: {
    ImportedBadge,
    TimeAgoTooltip,
    GlBadge,
    GlLoadingIcon,
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    author: {
      type: Object,
      required: false,
      default: null,
    },
    createdAt: {
      type: String,
      required: false,
      default: null,
    },
    noteId: {
      type: String,
      required: false,
      default: null,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    isImported: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteUrl: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    noteTimestampLink() {
      if (this.noteUrl) return this.noteUrl;

      if (this.noteId) {
        let { noteId } = this;

        if (isGid(noteId)) noteId = getIdFromGraphQLId(noteId);

        return `#note_${noteId}`;
      }

      return undefined;
    },
    internalNoteTooltip() {
      return s__('Notes|This internal note will always remain confidential');
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-min-w-0 gl-flex-wrap gl-items-center gl-gap-3">
    <template v-if="author">
      <span class="gl-flex">
        <gl-avatar-link
          :href="author.path"
          :data-user-id="authorId"
          :data-username="author.username"
          class="js-user-link"
        >
          <gl-avatar
            :src="author.avatar_url"
            :entity-name="author.username"
            :alt="author.name"
            :size="24"
          />
          <slot name="avatar-badge"></slot>
        </gl-avatar-link>
      </span>
      <a
        :href="author.path || author.webUrl"
        class="js-user-link gl-overflow-hidden gl-break-words gl-text-default hover:gl-text-link focus:gl-focus"
        :data-user-id="authorId"
        :data-username="author.username"
      >
        <span class="gl-font-bold" data-testid="author-name" v-text="author.name"></span
        ><span
          class="gl-ml-2 gl-inline-block gl-max-w-full gl-truncate gl-whitespace-nowrap gl-align-bottom @max-sm/discussion:gl-hidden"
        >
          <span class="gl-text-subtle">@{{ author.username }}</span>
          <slot name="note-header-info"></slot>
        </span>
      </a>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="gl-flex gl-flex-wrap gl-items-center gl-gap-1 gl-text-subtle">
      <template v-if="createdAt">
        <span></span>
        <time-ago-tooltip
          v-if="noteTimestampLink"
          :href="noteTimestampLink"
          class="gl-text-subtle hover:gl-text-link"
          :time="createdAt"
          tooltip-placement="bottom"
        />
        <time-ago-tooltip v-else :time="createdAt" tooltip-placement="bottom" />
      </template>
      <imported-badge v-if="isImported" />
      <gl-badge
        v-if="isInternalNote"
        v-gl-tooltip:tooltipcontainer.bottom
        data-testid="internal-note-indicator"
        variant="warning"
        class="gl-ml-2"
        :title="internalNoteTooltip"
      >
        {{ __('Internal note') }}
      </gl-badge>
      <slot name="extra-controls"></slot>
      <gl-loading-icon
        v-if="isUpdating"
        size="sm"
        class="gl-ml-2"
        :label="__('Comment is being updated')"
      />
    </span>
  </div>
</template>
