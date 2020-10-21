<script>
import { GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
import limitWarning from './limit_warning_component.vue';
import totalTime from './total_time_component.vue';

export default {
  components: {
    userAvatarImage,
    totalTime,
    limitWarning,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    items: {
      type: Array,
      default: () => [],
      required: false,
    },
    stage: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
};
</script>
<template>
  <div>
    <div class="events-description">
      {{ stage.description }}
      <limit-warning :count="items.length" />
    </div>
    <ul class="stage-event-list">
      <li v-for="(build, i) in items" :key="i" class="stage-event-item item-build-component">
        <div class="item-details">
          <!-- FIXME: Pass an alt attribute here for accessibility -->
          <user-avatar-image :img-src="build.author.avatarUrl" />
          <h5 class="item-title">
            <a :href="build.url" class="pipeline-id"> #{{ build.id }} </a>
            <gl-icon :size="16" name="fork" />
            <a :href="build.branch.url" class="ref-name"> {{ build.branch.name }} </a>
            <span class="icon-branch gl-text-gray-400">
              <gl-icon name="commit" :size="14" />
            </span>
            <a :href="build.commitUrl" class="commit-sha"> {{ build.shortSha }} </a>
          </h5>
          <span>
            <a :href="build.url" class="build-date"> {{ build.date }} </a> {{ s__('ByAuthor|by') }}
            <a :href="build.author.webUrl" class="issue-author-link"> {{ build.author.name }} </a>
          </span>
        </div>
        <div class="item-time"><total-time :time="build.totalTime" /></div>
      </li>
    </ul>
  </div>
</template>
