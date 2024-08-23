<script>
import { GlAlert, GlButton, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { get } from 'lodash';
import { formatDate } from '~/lib/utils/datetime_utility';
import axios from '~/lib/utils/axios_utils';

import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlAreaChart,
    GlButton,
    GlCollapsibleListbox,
    GlSprintf,
  },
  props: {
    graphEndpoint: {
      type: String,
      required: true,
    },
    graphEndDate: {
      type: String,
      required: true,
    },
    graphStartDate: {
      type: String,
      required: true,
    },
    graphRef: {
      type: String,
      required: true,
    },
    graphCsvPath: {
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
          type: 'time',
          axisLabel: {
            formatter: (value) => formatDate(value, 'mmm dd'),
          },
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
      return this.sortedData.map((value) => [value.date, value.coverage]);
    },
    mappedCoverages() {
      return this.dailyCoverageData?.map((item, index) => ({
        // A numerical index makes an item into a group header, so
        // convert these to strings to get non-header GlCollapsibleListbox items
        value: index.toString(),
        text: item.group_name,
      }));
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
      this.tooltipTitle = formatDate(params.value, 'mmm dd');
      this.coveragePercentage = get(params, 'seriesData[0].data[1]', '');
    },
  },
  height: 200,
};
</script>

<template>
  <div>
    <div class="gl-border-t gl-mb-3 gl-flex gl-items-center gl-justify-between gl-pt-4">
      <h4 class="gl-m-0" sub-header>
        <gl-sprintf
          :message="__('Code coverage statistics for %{ref} %{start_date} - %{end_date}')"
        >
          <template #ref>
            <strong> {{ graphRef }} </strong>
          </template>
          <template #start_date>
            <strong> {{ graphStartDate }} </strong>
          </template>
          <template #end_date>
            <strong> {{ graphEndDate }} </strong>
          </template>
        </gl-sprintf>
      </h4>
      <gl-button v-if="canShowData" size="small" data-testid="download-button" :href="graphCsvPath">
        {{ __('Download raw data (.csv)') }}
      </gl-button>
    </div>
    <div class="gl-mb-3 gl-mt-3">
      <gl-alert
        v-if="hasFetchError"
        variant="danger"
        :title="s__('Code Coverage|Couldn\'t fetch the code coverage data')"
        :dismissible="false"
      />
      <gl-alert
        v-if="noDataAvailable"
        variant="info"
        :title="s__('Code Coverage|No code coverage data')"
        :dismissible="false"
      >
        <span>
          {{ __('Code coverage results are not yet available. Try again later.') }}
        </span>
      </gl-alert>
      <gl-collapsible-listbox
        v-if="canShowData"
        :items="mappedCoverages"
        :selected="selectedCoverageIndex.toString()"
        :toggle-text="selectedDailyCoverageName"
        @select="setSelectedCoverage"
      />
    </div>
    <gl-area-chart
      v-if="!isLoading"
      :height="$options.height"
      :data="chartData"
      :option="chartOptions"
      :format-tooltip-text="formatTooltipText"
      responsive
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
