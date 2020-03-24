<script>
import { s__ } from '~/locale';
import { mapActions, mapState } from 'vuex';
import { GlIcon, GlDropdown, GlDropdownHeader, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownHeader,
    GlDropdownItem,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    ...mapState('environmentLogs', ['pods']),

    podDropdownText() {
      return this.pods.current || s__('Environments|No pod selected');
    },
  },
  methods: {
    ...mapActions('environmentLogs', ['showPodLogs']),
    isCurrentPod(podName) {
      return podName === this.pods.current;
    },
  },
};
</script>
<template>
  <div>
    <gl-dropdown
      ref="podsDropdown"
      :text="podDropdownText"
      :disabled="disabled"
      class="mb-2 gl-h-32 pr-2 d-flex d-md-block flex-grow-0 qa-pods-dropdown"
    >
      <gl-dropdown-header class="text-center">
        {{ s__('Environments|Select pod') }}
      </gl-dropdown-header>

      <gl-dropdown-item v-if="!pods.options.length" disabled>
        <span ref="noPodsMsg" class="text-muted">
          {{ s__('Environments|No pods to display') }}
        </span>
      </gl-dropdown-item>
      <gl-dropdown-item
        v-for="podName in pods.options"
        :key="podName"
        class="text-nowrap"
        @click="showPodLogs(podName)"
      >
        <div class="d-flex">
          <gl-icon
            :class="{ invisible: !isCurrentPod(podName) }"
            name="status_success_borderless"
          />
          <div class="flex-grow-1">{{ podName }}</div>
        </div>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
