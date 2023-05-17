<script>
import { GlAvatarLink, GlSprintf } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

export default {
  components: {
    GlAvatarLink,
    GlSprintf,
    TimeAgoTooltip,
  },
  inject: ['fullPath'],
  props: {
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    createdAt() {
      return this.workItem?.createdAt || '';
    },
    updatedAt() {
      return this.workItem?.updatedAt || '';
    },
    author() {
      return this.workItem?.author ?? {};
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data.workspace.workItems.nodes[0] ?? {};
      },
    },
  },
};
</script>

<template>
  <div class="gl-mb-3">
    <span data-testid="work-item-created">
      <gl-sprintf v-if="author.name" :message="__('Created %{timeAgo} by %{author}')">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
        <template #author>
          <gl-avatar-link
            class="js-user-link gl-text-body gl-font-weight-bold"
            :title="author.name"
            :data-user-id="authorId"
            :href="author.webUrl"
          >
            {{ author.name }}
          </gl-avatar-link>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else-if="createdAt" :message="__('Created %{timeAgo}')">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
      </gl-sprintf>
    </span>

    <span
      v-if="updatedAt"
      class="gl-ml-5 gl-display-none gl-sm-display-inline-block"
      data-testid="work-item-updated"
    >
      <gl-sprintf :message="__('Updated %{timeAgo}')">
        <template #timeAgo>
          <time-ago-tooltip :time="updatedAt" />
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
