<script>
import {
  GlModalDirective,
  GlTooltipDirective,
  GlFriendlyWrap,
  GlIcon,
  GlLink,
  GlButton,
  GlPagination,
  GlEmptyState,
  GlSprintf,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import TestCaseDetails from './test_case_details.vue';

export const i18n = {
  expiredArtifactsTitle: s__('TestReports|Job artifacts are expired'),
  expiredArtifactsDescription: s__(
    'TestReports|Test reports require job artifacts but all artifacts are expired. %{linkStart}Learn more%{linkEnd}',
  ),
};

export default {
  name: 'TestsSuiteTable',
  components: {
    GlIcon,
    GlFriendlyWrap,
    GlLink,
    GlButton,
    GlPagination,
    GlEmptyState,
    GlSprintf,
    TestCaseDetails,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  inject: {
    artifactsExpiredImagePath: {
      default: '',
    },
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: __('Tests'),
    },
  },
  computed: {
    ...mapState('testReports', ['pageInfo']),
    ...mapGetters('testReports', [
      'getSuiteTests',
      'getSuiteTestCount',
      'getSuiteArtifactsExpired',
    ]),
    hasSuites() {
      return this.getSuiteTests.length > 0;
    },
  },
  methods: {
    ...mapActions('testReports', ['setPage']),
  },
  wrapSymbols: ['::', '#', '.', '_', '-', '/', '\\'],
  i18n,
  learnMorePath: helpPagePath('ci/testing/unit_test_reports', {
    anchor: 'view-unit-test-reports-on-gitlab',
  }),
};
</script>

<template>
  <div>
    <div v-if="hasSuites" class="test-reports-table js-test-cases-table gl-mb-3">
      <div class="row gl-mt-3">
        <div class="col-12">
          <h4>{{ heading }}</h4>
        </div>
      </div>
      <div
        role="row"
        class="gl-responsive-table-row table-row-header gl-fill-gray-700 gl-font-bold"
      >
        <div role="rowheader" class="table-section section-20">
          {{ __('Suite') }}
        </div>
        <div role="rowheader" class="table-section section-40">
          {{ __('Name') }}
        </div>
        <div role="rowheader" class="table-section section-10">
          {{ __('Filename') }}
        </div>
        <div role="rowheader" class="table-section section-10 text-center">
          {{ __('Status') }}
        </div>
        <div role="rowheader" class="table-section section-10">
          {{ __('Duration') }}
        </div>
        <div role="rowheader" class="table-section section-10">
          {{ __('Details') }}
        </div>
      </div>

      <div
        v-for="(testCase, index) in getSuiteTests"
        :key="index"
        class="gl-responsive-table-row gl-items-start gl-rounded-base"
        data-testid="test-case-row"
      >
        <div class="table-section section-20 section-wrap">
          <div role="rowheader" class="table-mobile-header">{{ __('Suite') }}</div>
          <div class="table-mobile-content gl-break-words gl-pr-0 sm:gl-pr-2">
            <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="testCase.classname" />
          </div>
        </div>

        <div class="table-section section-40 section-wrap">
          <div role="rowheader" class="table-mobile-header">{{ __('Name') }}</div>
          <div class="table-mobile-content gl-break-words gl-pr-0 sm:gl-pr-2">
            <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="testCase.name" />
          </div>
        </div>

        <div class="table-section section-10 section-wrap">
          <div role="rowheader" class="table-mobile-header">{{ __('Filename') }}</div>
          <div class="table-mobile-content gl-break-words gl-pr-0 sm:gl-pr-2">
            <gl-link v-if="testCase.file" :href="testCase.filePath" target="_blank">
              <gl-friendly-wrap :symbols="$options.wrapSymbols" :text="testCase.file" />
            </gl-link>
            <gl-button
              v-if="testCase.file"
              v-gl-tooltip
              size="small"
              category="tertiary"
              icon="copy-to-clipboard"
              :title="__('Copy to clipboard')"
              :data-clipboard-text="testCase.file"
              :aria-label="__('Copy to clipboard')"
            />
          </div>
        </div>

        <div class="table-section section-10 section-wrap">
          <div role="rowheader" class="table-mobile-header">{{ __('Status') }}</div>
          <div class="table-mobile-content gl-justify-center md:gl-flex">
            <div class="ci-status-icon" :class="`ci-status-icon-${testCase.status}`">
              <gl-icon :size="24" :name="testCase.icon" />
            </div>
          </div>
        </div>

        <div class="table-section section-10 section-wrap">
          <div role="rowheader" class="table-mobile-header">
            {{ __('Duration') }}
          </div>
          <div class="table-mobile-content gl-pr-0 sm:gl-pr-2">
            {{ testCase.formattedTime }}
          </div>
        </div>

        <div class="table-section section-10 section-wrap">
          <div role="rowheader" class="table-mobile-header">{{ __('Details') }}</div>
          <div class="table-mobile-content">
            <gl-button v-gl-modal-directive="`test-case-details-${index}`">{{
              __('View details')
            }}</gl-button>
            <test-case-details :modal-id="`test-case-details-${index}`" :test-case="testCase" />
          </div>
        </div>
      </div>

      <gl-pagination
        v-model="pageInfo.page"
        class="gl-flex gl-justify-center"
        :per-page="pageInfo.perPage"
        :total-items="getSuiteTestCount"
        @input="setPage"
      />
    </div>

    <div v-else>
      <gl-empty-state
        v-if="getSuiteArtifactsExpired"
        :title="$options.i18n.expiredArtifactsTitle"
        :svg-path="artifactsExpiredImagePath"
        :svg-height="100"
        data-testid="artifacts-expired"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.expiredArtifactsDescription">
            <template #link="{ content }">
              <gl-link :href="$options.learnMorePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-empty-state>
      <p v-else data-testid="no-test-cases">
        {{ s__('TestReports|There are no test cases to display.') }}
      </p>
    </div>
  </div>
</template>
