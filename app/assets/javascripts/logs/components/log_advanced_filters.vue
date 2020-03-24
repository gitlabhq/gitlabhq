<script>
import { s__ } from '~/locale';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { mapActions, mapState } from 'vuex';
import {
  GlIcon,
  GlDropdown,
  GlDropdownHeader,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByClick,
} from '@gitlab/ui';
import { timeRanges } from '~/vue_shared/constants';

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownHeader,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByClick,
    DateTimePicker,
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
      timeRanges,
      searchQuery: '',
    };
  },
  computed: {
    ...mapState('environmentLogs', ['timeRange', 'pods']),

    timeRangeModel: {
      get() {
        return this.timeRange.selected;
      },
      set(val) {
        this.setTimeRange(val);
      },
    },

    podDropdownText() {
      return this.pods.current || s__('Environments|All pods');
    },
  },
  methods: {
    ...mapActions('environmentLogs', ['setSearch', 'showPodLogs', 'setTimeRange']),
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
        {{ s__('Environments|Filter by pod') }}
      </gl-dropdown-header>

      <gl-dropdown-item v-if="!pods.options.length" disabled>
        <span ref="noPodsMsg" class="text-muted">
          {{ s__('Environments|No pods to display') }}
        </span>
      </gl-dropdown-item>

      <template v-else>
        <gl-dropdown-item ref="allPodsOption" key="all-pods" @click="showPodLogs(null)">
          <div class="d-flex">
            <gl-icon
              :class="{ invisible: pods.current !== null }"
              name="status_success_borderless"
            />
            <div class="flex-grow-1">{{ s__('Environments|All pods') }}</div>
          </div>
        </gl-dropdown-item>
        <gl-dropdown-divider />
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
      </template>
    </gl-dropdown>

    <gl-search-box-by-click
      ref="searchBox"
      v-model.trim="searchQuery"
      :disabled="disabled"
      :placeholder="s__('Environments|Search')"
      class="mb-2 pr-2 flex-grow-1"
      type="search"
      autofocus
      @submit="setSearch(searchQuery)"
    />

    <date-time-picker
      ref="dateTimePicker"
      v-model="timeRangeModel"
      :disabled="disabled"
      :options="timeRanges"
      class="mb-2 gl-h-32 pr-2 d-block date-time-picker-wrapper"
      right
    />
  </div>
</template>
