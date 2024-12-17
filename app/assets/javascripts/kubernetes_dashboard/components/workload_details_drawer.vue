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
      selectedSection: '',
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
    toggle(item, section) {
      if (!isEqual(item, this.selectedItem)) {
        this.open(item, section);
      } else {
        this.close();
      }
    },
    open(item, section) {
      this.selectedItem = item;
      this.selectedSection = section;
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
      this.selectedSection = '';
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
        :selected-section="selectedSection"
        :configuration="configuration"
        @delete-pod="onDeletePod"
        @flux-reconcile="$emit('flux-reconcile')"
        @flux-suspend="$emit('flux-suspend')"
        @flux-resume="$emit('flux-resume')"
      />
    </template>
  </gl-drawer>
</template>
