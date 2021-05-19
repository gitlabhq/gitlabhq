<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import { timeRanges } from '~/vue_shared/constants';
import { TOKEN_TYPE_POD_NAME } from '../constants';
import TokenWithLoadingState from './tokens/token_with_loading_state.vue';

export default {
  components: {
    GlFilteredSearch,
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
    };
  },
  computed: {
    ...mapState('environmentLogs', ['timeRange', 'pods', 'logs']),

    timeRangeModel: {
      get() {
        return this.timeRange.selected;
      },
      set(val) {
        this.setTimeRange(val);
      },
    },
    /**
     * Token options.
     *
     * Returns null when no pods are present, so suggestions are displayed in the token
     */
    podOptions() {
      if (this.pods.options.length) {
        return this.pods.options.map((podName) => ({ value: podName, title: podName }));
      }
      return null;
    },

    tokens() {
      return [
        {
          icon: 'pod',
          type: TOKEN_TYPE_POD_NAME,
          title: s__('Environments|Pod name'),
          token: TokenWithLoadingState,
          operators: OPERATOR_IS_ONLY,
          unique: true,
          options: this.podOptions,
          loading: this.logs.isLoading,
          noOptionsText: s__('Environments|No pods to display'),
        },
      ];
    },
  },
  methods: {
    ...mapActions('environmentLogs', ['showFilteredLogs', 'setTimeRange']),

    filteredSearchSubmit(filters) {
      this.showFilteredLogs(filters);
    },
  },
};
</script>
<template>
  <div>
    <div class="mb-2 pr-2 flex-grow-1 min-width-0">
      <gl-filtered-search
        :placeholder="__('Search')"
        :clear-button-title="__('Clear')"
        :close-button-title="__('Close')"
        class="gl-h-32"
        :disabled="disabled || logs.isLoading"
        :available-tokens="tokens"
        @submit="filteredSearchSubmit"
      />
    </div>

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
