<script>
import workItemQuery from '../graphql/work_item.query.graphql';
import { widgetTypes } from '../constants';

export default {
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      workItem: null,
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
    },
  },
  computed: {
    titleWidgetData() {
      return this.workItem?.widgets?.nodes?.find((widget) => widget.type === widgetTypes.title);
    },
  },
};
</script>

<template>
  <section>
    <!-- Title widget placeholder -->
    <div>
      <h2
        v-if="titleWidgetData"
        class="gl-font-weight-normal gl-sm-font-weight-bold gl-my-5"
        data-testid="title"
      >
        {{ titleWidgetData.contentText }}
      </h2>
    </div>
  </section>
</template>
