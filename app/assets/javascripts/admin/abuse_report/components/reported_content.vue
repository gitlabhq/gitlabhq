<script>
import { GlButton, GlModal, GlCard, GlLink, GlAvatar } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TruncatedText from '~/vue_shared/components/truncated_text/truncated_text.vue';
import { REPORTED_CONTENT_I18N } from '../constants';

export default {
  name: 'ReportedContent',
  components: {
    GlButton,
    GlModal,
    GlCard,
    GlLink,
    GlAvatar,
    TimeAgoTooltip,
    TruncatedText,
  },
  modalId: 'abuse-report-screenshot-modal',
  directives: {
    SafeHtml,
  },
  props: {
    report: {
      type: Object,
      required: true,
    },
    reporter: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      showScreenshotModal: false,
    };
  },
  computed: {
    reporterName() {
      return this.reporter?.name || this.$options.i18n.deletedReporter;
    },
    reportType() {
      return this.report.type || 'unknown';
    },
  },
  mounted() {
    renderGFM(this.$refs.gfmContent);
  },
  methods: {
    toggleScreenshotModal() {
      this.showScreenshotModal = !this.showScreenshotModal;
    },
  },
  i18n: REPORTED_CONTENT_I18N,
  screenshotModalButtonAttributes: {
    text: __('Close'),
    attributes: {
      variant: 'confirm',
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <div class="gl-pt-6">
    <div
      class="gl-pb-3 gl-display-flex gl-justify-content-space-between gl-xs-flex-direction-column"
    >
      <h2 class="gl-font-size-h1 gl-mt-0 gl-mb-2">
        {{ $options.i18n.reportTypes[reportType] }}
      </h2>
      <div
        class="gl-display-flex gl-align-items-stretch gl-xs-flex-direction-column gl-mt-3 gl-sm-mt-0"
      >
        <template v-if="report.screenshot">
          <gl-button data-testid="screenshot-button" @click="toggleScreenshotModal">
            {{ $options.i18n.viewScreenshot }}
          </gl-button>
          <gl-modal
            v-model="showScreenshotModal"
            :title="$options.i18n.screenshotTitle"
            :modal-id="$options.modalId"
            :action-primary="$options.screenshotModalButtonAttributes"
          >
            <img
              :src="report.screenshot"
              :alt="$options.i18n.screenshotTitle"
              class="gl-w-full gl-h-auto"
            />
          </gl-modal>
        </template>
        <gl-button
          v-if="report.url"
          data-testid="report-url-button"
          :href="report.url"
          class="gl-sm-ml-3 gl-mt-3 gl-sm-mt-0"
        >
          {{ $options.i18n.goToType[reportType] }}
        </gl-button>
      </div>
    </div>
    <gl-card
      header-class="gl-bg-white js-test-card-header"
      body-class="gl-bg-gray-50 gl-px-5 gl-py-3 js-test-card-body"
      footer-class="gl-bg-white js-test-card-footer"
    >
      <template v-if="report.content" #header>
        <truncated-text>
          <div
            ref="gfmContent"
            v-safe-html:[$options.safeHtmlConfig]="report.content"
            class="md"
          ></div>
        </truncated-text>
      </template>
      {{ $options.i18n.reportedBy }}
      <template #footer>
        <div class="gl-display-flex gl-align-items-center gl-mb-2">
          <gl-avatar :size="32" :src="reporter && reporter.avatarUrl" />
          <div class="gl-display-flex gl-flex-wrap">
            <span class="gl-ml-3 gl-font-weight-bold">
              {{ reporterName }}
            </span>
            <gl-link v-if="reporter" :href="reporter.path" class="gl-ml-3">
              @{{ reporter.username }}
            </gl-link>
            <time-ago-tooltip
              :time="report.reportedAt"
              class="gl-ml-3 gl-text-secondary gl-xs-w-full"
            />
          </div>
        </div>
        <p v-if="report.message" class="gl-pl-8 gl-mb-0">{{ report.message }}</p>
      </template>
    </gl-card>
  </div>
</template>
