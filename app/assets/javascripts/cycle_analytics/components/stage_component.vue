<script>
  import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component.vue';

  export default {
    components: {
      userAvatarImage,
      limitWarning,
      totalTime,
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
        v-for="(issue, i) in items"
        :key="i"
        class="stage-event-item"
      >
        <div class="item-details">
          <!-- FIXME: Pass an alt attribute here for accessibility -->
          <user-avatar-image :img-src="issue.author.avatarUrl"/>
          <h5 class="item-title issue-title">
            <a
              class="issue-title"
              :href="issue.url"
            >
              {{ issue.title }}
            </a>
          </h5>
          <a
            :href="issue.url"
            class="issue-link"
          >#{{ issue.iid }}</a>
          &middot;
          <span>
            {{ s__('OpenedNDaysAgo|Opened') }}
            <a
              :href="issue.url"
              class="issue-date"
            >{{ issue.createdAt }}</a>
          </span>
          <span>
            {{ s__('ByAuthor|by') }}
            <a
              :href="issue.author.webUrl"
              class="issue-author-link"
            >
              {{ issue.author.name }}
            </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="issue.totalTime" />
        </div>
      </li>
    </ul>
  </div>
</template>

