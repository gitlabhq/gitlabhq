<script>
  import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component.vue';

  export default {
    props: {
      items: Array,
      stage: Object,
    },
    components: {
      userAvatarImage,
      limitWarning,
      totalTime,
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
      <li v-for="mergeRequest in items" class="stage-event-item">
        <div class="item-details">
          <!-- FIXME: Pass an alt attribute here for accessibility -->
          <user-avatar-image :img-src="mergeRequest.author.avatarUrl"/>
          <h5 class="item-title merge-merquest-title">
            <a :href="mergeRequest.url">
              {{ mergeRequest.title }}
            </a>
          </h5>
          <a :href="mergeRequest.url" class="issue-link">!{{ mergeRequest.iid }}</a>
          &middot;
          <span>
            {{ s__('OpenedNDaysAgo|Opened') }}
            <a :href="mergeRequest.url" class="issue-date">{{ mergeRequest.createdAt }}</a>
          </span>
          <span>
            {{ s__('ByAuthor|by') }}
            <a :href="mergeRequest.author.webUrl" class="issue-author-link">{{ mergeRequest.author.name }}</a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="mergeRequest.totalTime"></total-time>
        </div>
      </li>
    </ul>
  </div>
</template>
