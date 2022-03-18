<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import workItemQuery from '../graphql/work_item.query.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { WI_TITLE_TRACK_LABEL } from '../constants';

import ItemTitle from '../components/item_title.vue';

const trackingMixin = Tracking.mixin();

export default {
  titleUpdatedEvent: 'updated_title',
  components: {
    ItemTitle,
    GlAlert,
    GlLoadingIcon,
  },
  mixins: [trackingMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      workItem: {},
      error: false,
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.gid,
        };
      },
    },
  },
  computed: {
    tracking() {
      return {
        category: 'workItems:show',
        action: 'updated_title',
        label: WI_TITLE_TRACK_LABEL,
        property: '[type_work_item]',
      };
    },
    gid() {
      return convertToGraphQLId('WorkItem', this.id);
    },
  },
  methods: {
    async updateWorkItem(updatedTitle) {
      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.gid,
              title: updatedTitle,
            },
          },
        });
        this.track();
      } catch {
        this.error = true;
      }
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">{{
      __('Something went wrong while updating work item. Please try again')
    }}</gl-alert>
    <!-- Title widget placeholder -->
    <div>
      <gl-loading-icon
        v-if="$apollo.queries.workItem.loading"
        size="md"
        data-testid="loading-types"
      />
      <template v-else>
        <item-title
          :initial-title="workItem.title"
          data-testid="title"
          @title-changed="updateWorkItem"
        />
      </template>
    </div>
  </section>
</template>
