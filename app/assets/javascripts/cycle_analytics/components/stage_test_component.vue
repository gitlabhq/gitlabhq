<script>
  import iconBuildStatus from '../svg/icon_build_status.svg';
  import iconBranch from '../svg/icon_branch.svg';
  import limitWarning from './limit_warning_component.vue';
  import totalTime from './total_time_component.vue';
  import icon from '../../vue_shared/components/icon.vue';

  export default {
    components: {
      totalTime,
      limitWarning,
      icon,
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
      iconBuildStatus() {
        return iconBuildStatus;
      },
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
        :key="i"
        class="stage-event-item item-build-component"
      >
        <div class="item-details">
          <h5 class="item-title">
            <span
              class="icon-build-status"
              v-html="iconBuildStatus"
            >
            </span>
            <a
              :href="build.url"
              class="item-build-name"
            >
              {{ build.name }}
            </a>
            &middot;
            <a
              :href="build.url"
              class="pipeline-id"
            >
              #{{ build.id }}
            </a>
            <icon
              name="fork"
              :size="16"
            />
            <a
              :href="build.branch.url"
              class="ref-name"
            >
              {{ build.branch.name }}
            </a>
            <span
              class="icon-branch"
              v-html="iconBranch"
            >
            </span>
            <a
              :href="build.commitUrl"
              class="commit-sha">
              {{ build.shortSha }}
            </a>
          </h5>
          <span>
            <a
              :href="build.url"
              class="issue-date">
              {{ build.date }}
            </a>
          </span>
        </div>
        <div class="item-time">
          <total-time :time="build.totalTime" />
        </div>
      </li>
    </ul>
  </div>
</template>
