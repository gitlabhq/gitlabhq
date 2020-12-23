<script>
import { GlAlert, GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { get } from 'lodash';
import axios from '~/lib/utils/axios_utils';

import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlAreaChart,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
  },
  props: {
    graphEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      dailyCoverageData: [],
      hasFetchError: false,
      isLoading: true,
      selectedCoverageIndex: 0,
      tooltipTitle: '',
      coveragePercentage: '',
      chartOptions: {
        yAxis: {
          name: __('Bi-weekly code coverage'),
          type: 'value',
          min: 0,
          max: 100,
        },
        xAxis: {
          name: '',
          type: 'category',
        },
      },
    };
  },
  computed: {
    hasData() {
      return this.dailyCoverageData.length > 0;
    },
    isReady() {
      return !this.isLoading && !this.hasFetchError;
    },
    canShowData() {
      return this.isReady && this.hasData;
    },
    noDataAvailable() {
      return this.isReady && !this.hasData;
    },
    selectedDailyCoverage() {
      return this.hasData && this.dailyCoverageData[this.selectedCoverageIndex];
    },
    selectedDailyCoverageName() {
      return this.selectedDailyCoverage?.group_name;
    },
    sortedData() {
      // If the fetching failed, we return an empty array which
      // allow the graph to render while empty
      if (!this.selectedDailyCoverage?.data) {
        return [];
      }

      return [...this.selectedDailyCoverage.data].sort(
        (a, b) => new Date(a.date) - new Date(b.date),
      );
    },
    formattedData() {
      return this.sortedData.map((value) => [dateFormat(value.date, 'mmm dd'), value.coverage]);
    },
    chartData() {
      return [
        {
          // The default string 'data' will get shown in the legend if we fail to fetch the data
          name: this.canShowData ? this.selectedDailyCoverageName : __('data'),
          data: this.formattedData,
          type: 'line',
          smooth: true,
        },
      ];
    },
  },
  created() {
    axios
      .get(this.graphEndpoint)
      .then(({ data }) => {
        this.dailyCoverageData = data;
      })
      .catch(() => {
        this.hasFetchError = true;
      })
      .finally(() => {
        this.isLoading = false;
      });
  },
  methods: {
    setSelectedCoverage(index) {
      this.selectedCoverageIndex = index;
    },
    formatTooltipText(params) {
      this.tooltipTitle = params.value;
      this.coveragePercentage = get(params, 'seriesData[0].data[1]', '');
    },
  },
  height: 200,
};
</script>

<template>
  <div>
    <div class="gl-mt-3 gl-mb-3">
      <gl-alert
        v-if="hasFetchError"
        variant="danger"
        :title="s__('Code Coverage|Couldn\'t fetch the code coverage data')"
        :dismissible="false"
      />
      <gl-alert
        v-if="noDataAvailable"
        variant="info"
        :title="s__('Code Coverage| Empty code coverage data')"
        :dismissible="false"
      >
        <span>
          {{ __('It seems that there is currently no available data for code coverage') }}
        </span>
      </gl-alert>
      <gl-dropdown v-if="canShowData" :text="selectedDailyCoverageName">
        <gl-dropdown-item
          v-for="({ group_name }, index) in dailyCoverageData"
          :key="index"
          :value="group_name"
          :is-check-item="true"
          :is-checked="index === selectedCoverageIndex"
          @click="setSelectedCoverage(index)"
        >
          {{ group_name }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
    <gl-area-chart
      v-if="!isLoading"
      :height="$options.height"
      :data="chartData"
      :option="chartOptions"
      :format-tooltip-text="formatTooltipText"
    >
      <template v-if="canShowData" #tooltip-title>
        {{ tooltipTitle }}
      </template>
      <template v-if="canShowData" #tooltip-content>
        <gl-sprintf :message="__('Code Coverage: %{coveragePercentage}%{percentSymbol}')">
          <template #coveragePercentage>
            {{ coveragePercentage }}
          </template>
          <template #percentSymbol> % </template>
        </gl-sprintf>
      </template>
    </gl-area-chart>
  </div>
</template>
