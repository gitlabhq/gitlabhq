<script>
import { GlAvatar, GlLink, GlSprintf, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf, n__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { SNIPPET_VISIBILITY } from '~/snippets/constants';

export default {
  name: 'SnippetRow',
  i18n: {
    snippetInfo: s__('UserProfile|%{id} · created %{created} by %{author}'),
    updatedInfo: s__('UserProfile|updated %{updated}'),
    blobTooltip: s__('UserProfile|%{count} %{file}'),
  },
  components: {
    GlAvatar,
    GlLink,
    GlSprintf,
    GlIcon,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
    userInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    formattedId() {
      return `$${getIdFromGraphQLId(this.snippet.id)}`;
    },
    profilePath() {
      return `${gon.relative_url_root || ''}/${this.userInfo.username}`;
    },
    blobCount() {
      return this.snippet.blobs?.nodes?.length || 0;
    },
    commentsCount() {
      return this.snippet.notes?.nodes?.length || 0;
    },
    visibilityIcon() {
      return SNIPPET_VISIBILITY[this.snippet.visibilityLevel]?.icon;
    },
    blobTooltip() {
      return sprintf(this.$options.i18n.blobTooltip, {
        count: this.blobCount,
        file: n__('file', 'files', this.blobCount),
      });
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-py-5">
    <gl-avatar :size="48" :src="userInfo.avatarUrl" class="gl-mr-3" />
    <div class="gl-flex gl-flex-col gl-items-start">
      <gl-link
        data-testid="snippet-url"
        :href="snippet.webUrl"
        class="gl-mb-2 gl-font-bold gl-text-default"
        >{{ snippet.title }}</gl-link
      >
      <span class="gl-text-subtle">
        <gl-sprintf :message="$options.i18n.snippetInfo">
          <template #id>
            <span data-testid="snippet-id">{{ formattedId }}</span>
          </template>
          <template #created>
            <time-ago data-testid="snippet-created-at" :time="snippet.createdAt" />
          </template>
          <template #author>
            <gl-link data-testid="snippet-author" :href="profilePath" class="gl-text-default">{{
              userInfo.name
            }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </div>
    <div class="gl-ml-auto gl-flex gl-flex-col gl-items-end">
      <div class="gl-mb-2 gl-flex gl-items-center">
        <span
          v-gl-tooltip
          data-testid="snippet-blob"
          :title="blobTooltip"
          class="gl-mr-4"
          :class="{ 'gl-opacity-5': blobCount === 0 }"
        >
          <gl-icon name="documents" />
          <span>{{ blobCount }}</span>
        </span>
        <gl-link
          data-testid="snippet-comments"
          :href="`${snippet.webUrl}#notes`"
          class="gl-mr-4 gl-text-default"
          :class="{ 'gl-opacity-5': commentsCount === 0 }"
        >
          <gl-icon name="comments" />
          <span>{{ commentsCount }}</span>
        </gl-link>
        <gl-icon data-testid="snippet-visibility" :name="visibilityIcon" />
      </div>
      <span class="gl-text-subtle">
        <gl-sprintf :message="$options.i18n.updatedInfo">
          <template #updated>
            <time-ago data-testid="snippet-updated-at" :time="snippet.updatedAt" />
          </template>
        </gl-sprintf>
      </span>
    </div>
  </div>
</template>
