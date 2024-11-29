<script>
import { GlButton, GlModal, GlCard, GlLink, GlAvatar, GlTruncateText } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { REPORTED_CONTENT_I18N } from '../constants';

export default {
  name: 'ReportedContent',
  components: {
    GlButton,
    GlModal,
    GlCard,
    GlLink,
    GlAvatar,
    GlTruncateText,
    TimeAgoTooltip,
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
  },
  data() {
    return {
      showScreenshotModal: false,
    };
  },
  computed: {
    reporter() {
      return this.report.reporter;
    },
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
    <div class="gl-flex gl-flex-col gl-items-center gl-justify-between gl-pb-3 sm:gl-flex-row">
      <h2 class="gl-mb-2 gl-mt-2 gl-text-size-h1">
        {{ $options.i18n.reportTypes[reportType] }}
      </h2>

      <div class="gl-mt-3 gl-flex gl-flex-col gl-items-stretch sm:gl-mt-0 sm:gl-flex-row">
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
              class="gl-h-auto gl-w-full"
            />
          </gl-modal>
        </template>
        <gl-button
          v-if="report.url"
          data-testid="report-url-button"
          :href="report.url"
          class="gl-mt-3 sm:gl-ml-3 sm:gl-mt-0"
        >
          {{ $options.i18n.goToType[reportType] }}
        </gl-button>
      </div>
    </div>
    <gl-card
      header-class="js-test-card-header"
      body-class="gl-py-3 js-test-card-body"
      footer-class="js-test-card-footer"
    >
      <template v-if="report.content" #header>
        <gl-truncate-text>
          <div
            ref="gfmContent"
            v-safe-html:[$options.safeHtmlConfig]="report.content"
            class="md"
          ></div>
        </gl-truncate-text>
      </template>
      {{ $options.i18n.reportedBy }}
      <template #footer>
        <div class="gl-mb-2 gl-flex gl-items-center">
          <gl-avatar :size="32" :src="reporter && reporter.avatarUrl" />
          <div class="gl-flex gl-flex-wrap">
            <span class="gl-ml-3 gl-font-bold">
              {{ reporterName }}
            </span>
            <gl-link v-if="reporter" :href="reporter.path" class="gl-ml-3">
              @{{ reporter.username }}
            </gl-link>
            <time-ago-tooltip
              :time="report.reportedAt"
              class="gl-ml-3 gl-w-full gl-text-subtle sm:gl-w-auto"
            />
          </div>
        </div>
        <p v-if="report.message" class="gl-mb-0 gl-pl-8">{{ report.message }}</p>
      </template>
    </gl-card>
  </div>
</template>
