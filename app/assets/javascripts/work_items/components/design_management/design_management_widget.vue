<script>
import { __ } from '~/locale';
import { findDesignWidget } from '~/work_items/utils';

import WidgetWrapper from '../widget_wrapper.vue';
import getWorkItemDesignListQuery from './graphql/design_collection.query.graphql';
import Design from './design_item.vue';

export default {
  components: {
    Design,
    WidgetWrapper,
  },
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    designCollection: {
      query: getWorkItemDesignListQuery,
      variables() {
        return {
          id: this.workItemId,
          atVersion: null,
        };
      },
      update(data) {
        const designWidget = findDesignWidget(data.workItem.widgets);
        const { copyState } = designWidget.designCollection;
        const designNodes = designWidget.designCollection.designs.nodes;
        const versionNodes = designWidget.designCollection.versions.nodes;
        return {
          designs: designNodes,
          copyState,
          versions: versionNodes,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.error = this.$options.i18n.designLoadingError;
      },
    },
  },
  data() {
    return {
      designCollection: null,
      error: null,
    };
  },
  computed: {
    designs() {
      return this.designCollection?.designs || [];
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
  },
  i18n: {
    designLoadingError: __('An error occurred while loading designs. Please try again.'),
  },
};
</script>

<template>
  <widget-wrapper v-if="hasDesigns" data-testid="designs-root" :error="error">
    <template #header>
      <span class="gl-font-weight-bold gl-mr-3">{{ s__('DesignManagement|Designs') }}</span>
    </template>
    <template #body>
      <ol class="list-unstyled row gl-px-3">
        <li
          v-for="design in designs"
          :key="design.id"
          class="col-md-6 col-lg-3 gl-mt-5 gl-px-3 gl-bg-transparent gl-shadow-none js-design-tile"
        >
          <design v-bind="design" class="gl-bg-white" :is-uploading="false" />
        </li>
      </ol>
    </template>
  </widget-wrapper>
</template>
