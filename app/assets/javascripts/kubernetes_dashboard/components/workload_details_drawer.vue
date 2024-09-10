<script>
import { GlDrawer } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { InternalEvents } from '~/tracking';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  components: {
    WorkloadDetails,
    GlDrawer,
  },
  mixins: [trackingMixin],
  props: {
    configuration: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedItem: {},
      showDetailsDrawer: false,
      focusedElement: null,
    };
  },
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    hasSelectedItem() {
      return Object.keys(this.selectedItem).length;
    },
  },
  methods: {
    onDeletePod(pod) {
      this.$emit('delete-pod', pod);
    },
    onFluxReconcile() {
      this.$emit('flux-reconcile');
    },
    toggle(item) {
      if (!isEqual(item, this.selectedItem)) {
        this.open(item);
      } else {
        this.close();
      }
    },
    open(item) {
      this.selectedItem = item;
      this.showDetailsDrawer = true;
      this.trackEvent('open_kubernetes_resource_details', { label: item.kind });

      this.focusedElement = document.activeElement;
      this.$nextTick(() => {
        this.$refs.drawer?.$el?.querySelector('button')?.focus();
      });
    },
    close() {
      this.showDetailsDrawer = false;
      this.selectedItem = {};
      this.$nextTick(() => {
        this.focusedElement?.focus();
      });
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-drawer
    ref="drawer"
    :open="showDetailsDrawer"
    :header-height="drawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="close"
  >
    <template #title>
      <h2 class="gl-m-0 gl-font-bold gl-break-anywhere">
        {{ selectedItem.name }}
      </h2>
    </template>
    <template #default>
      <workload-details
        v-if="hasSelectedItem"
        :item="selectedItem"
        :configuration="configuration"
        @delete-pod="onDeletePod"
        @flux-reconcile="onFluxReconcile"
      />
    </template>
  </gl-drawer>
</template>
