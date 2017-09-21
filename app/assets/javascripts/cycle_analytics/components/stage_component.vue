
<script>
  import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component';

  export default {
    props: {
      items: {
        type: Array,
        required: false,
        default: () => [],
      },
      stage: {
        type: Object,
        required: false,
        default: () => {},
      },
      titleClassName: {
        type: String,
        required: false,
        default: '',
      },
    },
    components: {
      limitWarning,
      userAvatarImage,
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
      <li
        v-for="(item, index) in items"
        :key="index"
        class="stage-event-item">
        <div class="item-details">
          <user-avatar-image
            :img-src="item.author.avatarUrl"
            />

          <h5
            class="item-title"
            :class="titleClassName"∂>
            <a :href="item.url">
              {{ item.title }}
            </a>
          </h5>
          <a
            :href="item.url"
            class="issue-link">
            !{{ item.iid }}
          </a>
          &middot;
          <span>
            {{ s__('OpenedNDaysAgo|Opened') }}
            <a
              :href="item.url"
              class="issue-date">
              {{ item.createdAt }}</a>
          </span>
          <span>
            {{ s__('ByAuthor|by') }}
            <a
              :href="item.author.webUrl"
              class="issue-author-link">
              {{ item.author.name }}
            </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="item.totalTime" />
        </div>
      </li>
    </ul>
  </div>
</template>
