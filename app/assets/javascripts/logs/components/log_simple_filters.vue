<script>
import { mapActions, mapState } from 'vuex';
import { GlDropdown, GlDropdownSectionHeader, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
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
      class="gl-mr-3 gl-mb-3 gl-display-flex gl-display-md-block qa-pods-dropdown"
    >
      <gl-dropdown-section-header>
        {{ s__('Environments|Select pod') }}
      </gl-dropdown-section-header>

      <gl-dropdown-item v-if="!pods.options.length" disabled>
        <span ref="noPodsMsg" class="text-muted">
          {{ s__('Environments|No pods to display') }}
        </span>
      </gl-dropdown-item>
      <gl-dropdown-item
        v-for="podName in pods.options"
        :key="podName"
        :is-check-item="true"
        :is-checked="isCurrentPod(podName)"
        class="text-nowrap"
        @click="showPodLogs(podName)"
      >
        {{ podName }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
