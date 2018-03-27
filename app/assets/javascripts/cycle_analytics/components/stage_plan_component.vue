<script>
  import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
  import iconCommit from '../svg/icon_commit.svg';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component.vue';

  export default {
    components: {
      userAvatarImage,
      totalTime,
      limitWarning,
    },
    props: {
      items: {
        type: Array,
        default: () => [],
      },
      stage: {
        type: Object,
        default: () => ({}),
      },
    },
    computed: {
      iconCommit() {
        return iconCommit;
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
        v-for="(commit, i) in items"
        :key="i"
        class="stage-event-item"
      >
        <div class="item-details item-conmmit-component">
          <!-- FIXME: Pass an alt attribute here for accessibility -->
          <user-avatar-image :img-src="commit.author.avatarUrl" />
          <h5 class="item-title commit-title">
            <a :href="commit.commitUrl">
              {{ commit.title }}
            </a>
          </h5>
          <span>
            {{ s__('FirstPushedBy|First') }}
            <span
              class="commit-icon"
              v-html="iconCommit"
            >
            </span>
            <a
              :href="commit.commitUrl"
              class="commit-hash-link commit-sha"
            >{{ commit.shortSha }}</a>
            {{ s__('FirstPushedBy|pushed by') }}
            <a
              :href="commit.author.webUrl"
              class="commit-author-link"
            >
              {{ commit.author.name }}
            </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="commit.totalTime" />
        </div>
      </li>
    </ul>
  </div>
</template>

