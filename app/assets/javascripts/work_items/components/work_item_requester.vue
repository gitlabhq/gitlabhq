<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import workItemRequesterQuery from '../graphql/work_item_requester.query.graphql';
import { findRequesterWidget } from '../utils';
import WorkItemSidebarWidget from './shared/work_item_sidebar_widget.vue';

export default {
  name: 'WorkItemRequester',
  components: {
    GlIcon,
    GlLink,
    WorkItemSidebarWidget,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      requester: null,
    };
  },
  apollo: {
    requester: {
      query: workItemRequesterQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        const workItem = data?.namespace?.workItem ?? {};
        return findRequesterWidget(workItem);
      },
      skip() {
        return !this.workItemIid;
      },
    },
  },
  computed: {
    email() {
      return this.requester?.email;
    },
  },
};
</script>

<template>
  <work-item-sidebar-widget v-if="email" data-testid="work-item-requester">
    <template #title>
      {{ s__('WorkItem|Requester') }}
    </template>
    <template #content>
      <gl-link class="gl-text-default" :href="`mailto:${email}`">
        <gl-icon name="mail" />
        {{ email }}
      </gl-link>
    </template>
  </work-item-sidebar-widget>
</template>
