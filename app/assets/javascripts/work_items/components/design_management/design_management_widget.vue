<script>
import { __ } from '~/locale';
import { TYPENAME_DESIGN_VERSION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { findDesignWidget } from '~/work_items/utils';

import WidgetWrapper from '../widget_wrapper.vue';
import getWorkItemDesignListQuery from './graphql/design_collection.query.graphql';
import Design from './design_item.vue';
import DesignVersionDropdown from './design_version_dropdown.vue';

export default {
  components: {
    Design,
    DesignVersionDropdown,
    WidgetWrapper,
  },
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: '',
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    designCollection: {
      query: getWorkItemDesignListQuery,
      variables() {
        return {
          id: this.workItemId,
          atVersion: this.designsVersion,
        };
      },
      update(data) {
        const designWidget = findDesignWidget(data.workItem.widgets);
        if (designWidget.designCollection === null) {
          return null;
        }
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
    allVersions() {
      return this.designCollection?.versions || [];
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
    hasValidVersion() {
      return (
        this.$route.query.version &&
        this.allVersions &&
        this.allVersions.some((version) => version.id.endsWith(this.$route.query.version))
      );
    },
    designsVersion() {
      return this.hasValidVersion
        ? convertToGraphQLId(TYPENAME_DESIGN_VERSION, this.$route.query.version)
        : null;
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
      <span class="gl-font-bold gl-mr-3">{{ s__('DesignManagement|Designs') }}</span>
    </template>
    <template #header-suffix>
      <design-version-dropdown :all-versions="allVersions" />
    </template>
    <template #body>
      <ol class="list-unstyled row gl-px-3">
        <li
          v-for="design in designs"
          :key="design.id"
          class="col-md-6 col-lg-3 gl-mt-5 gl-px-3 gl-bg-transparent gl-shadow-none js-design-tile"
        >
          <design
            v-bind="design"
            class="gl-bg-white"
            :is-uploading="false"
            :work-item-iid="workItemIid"
          />
        </li>
      </ol>
      <router-view :key="$route.fullPath" :all-designs="designs" />
    </template>
  </widget-wrapper>
</template>
