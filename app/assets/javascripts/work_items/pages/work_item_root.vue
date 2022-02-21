<script>
import { GlAlert } from '@gitlab/ui';
import Tracking from '~/tracking';
import workItemQuery from '../graphql/work_item.query.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { widgetTypes, WI_TITLE_TRACK_LABEL } from '../constants';

import ItemTitle from '../components/item_title.vue';

const trackingMixin = Tracking.mixin();

export default {
  titleUpdatedEvent: 'updated_title',
  components: {
    ItemTitle,
    GlAlert,
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
      workItem: null,
      error: false,
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.id,
        };
      },
      update(data) {
        return data.localWorkItem;
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
    titleWidgetData() {
      return this.workItem?.widgets?.nodes?.find((widget) => widget.type === widgetTypes.title);
    },
  },
  methods: {
    async updateWorkItem(title) {
      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.id,
              title,
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
      <item-title
        v-if="titleWidgetData"
        :initial-title="titleWidgetData.contentText"
        data-testid="title"
        @title-changed="updateWorkItem"
      />
    </div>
  </section>
</template>
