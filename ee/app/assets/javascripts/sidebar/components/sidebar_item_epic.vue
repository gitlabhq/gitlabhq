<script>
  import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
  import { __ } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import { spriteIcon } from '~/lib/utils/common_utils';
  import Store from '../stores/sidebar_store';

  export default {
    name: 'SidebarItemEpic',
    components: {
      LoadingIcon,
    },
    directives: {
      tooltip,
    },
    data() {
      return {
        store: new Store(),
      };
    },
    computed: {
      isLoading() {
        return this.store.isFetching.epic;
      },
      epicIcon() {
        return spriteIcon('epic');
      },
      epicUrl() {
        return this.store.epic.url;
      },
      epicTitle() {
        return this.store.epic.title;
      },
      hasEpic() {
        return this.epicUrl && this.epicTitle;
      },
      collapsedTitle() {
        return this.hasEpic ? this.epicTitle : 'None';
      },
      tooltipTitle() {
        if (!this.hasEpic) {
          return __('Epic');
        }
        let tooltipTitle = this.epicTitle;

        if (this.store.epic.human_readable_end_date || this.store.epic.human_readable_timestamp) {
          tooltipTitle += '<br />';
          tooltipTitle += this.store.epic.human_readable_end_date ? `${this.store.epic.human_readable_end_date} ` : '';
          tooltipTitle += this.store.epic.human_readable_timestamp ? `(${this.store.epic.human_readable_timestamp})` : '';
        }

        return tooltipTitle;
      },
    },
  };
</script>

<template>
  <div>
    <div
      class="sidebar-collapsed-icon"
      :title="tooltipTitle"
      data-container="body"
      data-placement="left"
      data-html="1"
      v-tooltip
    >
      <div v-html="epicIcon"></div>
      <span
        v-if="!isLoading"
        class="collapse-truncated-title"
      >
        {{ collapsedTitle }}
      </span>
    </div>
    <div class="title hide-collapsed">
      Epic
      <loading-icon
        v-if="isLoading"
        :inline="true"
      />
    </div>
    <div
      v-if="!isLoading"
      class="value hide-collapsed"
    >
      <a
        v-if="hasEpic"
        class="bold"
        :href="epicUrl"
      >
        {{ epicTitle }}
      </a>
      <span
        v-else
        class="no-value"
      >
        None
      </span>
    </div>
  </div>
</template>
