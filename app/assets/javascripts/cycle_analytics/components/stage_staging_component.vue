<script>
  import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
  import iconBranch from '../svg/icon_branch.svg';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component.vue';

  export default {
    props: {
      items: Array,
      stage: Object,
    },
    components: {
      userAvatarImage,
      totalTime,
      limitWarning,
    },
    computed: {
      iconBranch() {
        return iconBranch;
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
      <li
        v-for="(build, i) in items"
        class="stage-event-item item-build-component"
        :key="i">
        <div class="item-details">
          <!-- FIXME: Pass an alt attribute here for accessibility -->
          <user-avatar-image :img-src="build.author.avatarUrl"/>
          <h5 class="item-title">
            <a :href="build.url" class="pipeline-id">#{{ build.id }}</a>
            <i class="fa fa-code-fork"></i>
            <a :href="build.branch.url" class="ref-name">{{ build.branch.name }}</a>
            <span class="icon-branch" v-html="iconBranch"></span>
            <a :href="build.commitUrl" class="commit-sha">{{ build.shortSha }}</a>
          </h5>
          <span>
            <a :href="build.url" class="build-date">{{ build.date }}</a>
            {{ s__('ByAuthor|by') }}
            <a :href="build.author.webUrl" class="issue-author-link">
              {{ build.author.name }}
            </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="build.totalTime"/>
        </div>
      </li>
    </ul>
  </div>
</template>
