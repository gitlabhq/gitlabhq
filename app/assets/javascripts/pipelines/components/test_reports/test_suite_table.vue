<script>
import { mapGetters } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import store from '~/pipelines/stores/test_reports';
import { __ } from '~/locale';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';

export default {
  name: 'TestsSuiteTable',
  components: {
    Icon,
    SmartVirtualList,
  },
  store,
  props: {
    heading: {
      type: String,
      required: false,
      default: __('Tests'),
    },
  },
  computed: {
    ...mapGetters(['getSuiteTests']),
    hasSuites() {
      return this.getSuiteTests.length > 0;
    },
  },
  maxShownRows: 30,
  typicalRowHeight: 75,
};
</script>

<template>
  <div>
    <div class="row prepend-top-default">
      <div class="col-12">
        <h4>{{ heading }}</h4>
      </div>
    </div>

    <div v-if="hasSuites" class="test-reports-table append-bottom-default js-test-cases-table">
      <div role="row" class="gl-responsive-table-row table-row-header font-weight-bold fgray">
        <div role="rowheader" class="table-section section-20">
          {{ __('Class') }}
        </div>
        <div role="rowheader" class="table-section section-20">
          {{ __('Name') }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Status') }}
        </div>
        <div role="rowheader" class="table-section flex-grow-1">
          {{ __('Trace'), }}
        </div>
        <div role="rowheader" class="table-section section-10 text-right">
          {{ __('Duration') }}
        </div>
      </div>

      <smart-virtual-list
        :length="getSuiteTests.length"
        :remain="$options.maxShownRows"
        :size="$options.typicalRowHeight"
      >
        <div
          v-for="(testCase, index) in getSuiteTests"
          :key="index"
          class="gl-responsive-table-row rounded align-items-md-start mt-xs-3 js-case-row"
        >
          <div class="table-section section-20 section-wrap">
            <div role="rowheader" class="table-mobile-header">{{ __('Class') }}</div>
            <div class="table-mobile-content pr-md-1 text-truncate">{{ testCase.classname }}</div>
          </div>

          <div class="table-section section-20 section-wrap">
            <div role="rowheader" class="table-mobile-header">{{ __('Name') }}</div>
            <div class="table-mobile-content">{{ testCase.name }}</div>
          </div>

          <div class="table-section section-10 section-wrap">
            <div role="rowheader" class="table-mobile-header">{{ __('Status') }}</div>
            <div class="table-mobile-content text-center">
              <div
                class="add-border ci-status-icon d-flex align-items-center justify-content-end justify-content-md-center"
                :class="`ci-status-icon-${testCase.status}`"
              >
                <icon :size="24" :name="testCase.icon" />
              </div>
            </div>
          </div>

          <div class="table-section flex-grow-1">
            <div role="rowheader" class="table-mobile-header">{{ __('Trace'), }}</div>
            <div class="table-mobile-content">
              <pre
                v-if="testCase.system_output"
                class="build-trace build-trace-rounded text-left"
              ><code class="bash p-0">{{testCase.system_output}}</code></pre>
            </div>
          </div>

          <div class="table-section section-10 section-wrap">
            <div role="rowheader" class="table-mobile-header">
              {{ __('Duration') }}
            </div>
            <div class="table-mobile-content text-right pr-sm-1">
              {{ testCase.formattedTime }}
            </div>
          </div>
        </div>
      </smart-virtual-list>
    </div>

    <div v-else>
      <p class="js-no-test-cases">{{ s__('TestReports|There are no test cases to display.') }}</p>
    </div>
  </div>
</template>
