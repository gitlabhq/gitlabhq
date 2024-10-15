<script>
import {
  GlButton,
  GlTruncateText,
  GlModalDirective,
  GlTooltipDirective as GlTooltip,
  GlSprintf,
} from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import SafeHtml from '~/vue_shared/directives/safe_html';
import DeleteEnvironmentModal from './delete_environment_modal.vue';
import StopEnvironmentModal from './stop_environment_modal.vue';
import DeployFreezeAlert from './deploy_freeze_alert.vue';

export default {
  name: 'EnvironmentsDetailHeader',
  csrf,
  components: {
    GlButton,
    GlSprintf,
    GlTruncateText,
    TimeAgo,
    DeployFreezeAlert,
    DeleteEnvironmentModal,
    StopEnvironmentModal,
  },
  directives: {
    GlModalDirective,
    GlTooltip,
    SafeHtml,
  },
  mixins: [timeagoMixin],
  props: {
    environment: {
      type: Object,
      required: true,
    },
    canAdminEnvironment: {
      type: Boolean,
      required: true,
    },
    canUpdateEnvironment: {
      type: Boolean,
      required: true,
    },
    canDestroyEnvironment: {
      type: Boolean,
      required: true,
    },
    canStopEnvironment: {
      type: Boolean,
      required: true,
    },
    cancelAutoStopPath: {
      type: String,
      required: false,
      default: '',
    },
    updatePath: {
      type: String,
      required: false,
      default: '',
    },
    terminalPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    autoStopAtText: s__('Environments|Auto stops %{autoStopAt}'),
    editButtonText: s__('Environments|Edit environment'),
    stopButtonText: s__('Environments|Stop'),
    deleteButtonText: s__('Environments|Delete'),
    externalButtonTitle: s__('Environments|Open live environment'),
    externalButtonText: __('View deployment'),
    cancelAutoStopButtonTitle: __('Prevent environment from auto-stopping'),
    showMoreText: __('Read more'),
  },
  computed: {
    shouldShowCancelAutoStopButton() {
      return this.environment.isAvailable && Boolean(this.environment.autoStopAt);
    },
    shouldShowExternalUrlButton() {
      return Boolean(this.environment.externalUrl);
    },
    shouldShowStopButton() {
      return this.canStopEnvironment && this.environment.isAvailable;
    },
    shouldShowTerminalButton() {
      return this.canAdminEnvironment && this.environment.hasTerminals;
    },
  },
  mounted() {
    renderGFM(this.$refs['gfm-content']);
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <div>
    <deploy-freeze-alert :name="environment.name" />
    <header class="top-area gl-justify-content-between gl-border-none">
      <div class="gl-flex gl-grow gl-items-center">
        <h1 class="page-title gl-text-size-h-display">
          {{ environment.name }}
        </h1>
        <p
          v-if="shouldShowCancelAutoStopButton"
          class="gl-mb-0 gl-ml-3"
          data-testid="auto-stops-at"
        >
          <gl-sprintf :message="$options.i18n.autoStopAtText">
            <template #autoStopAt>
              <time-ago :time="environment.autoStopAt" />
            </template>
          </gl-sprintf>
        </p>
      </div>
      <div class="nav-controls gl-my-1">
        <form method="POST" :action="cancelAutoStopPath" data-testid="cancel-auto-stop-form">
          <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
          <gl-button
            v-if="shouldShowCancelAutoStopButton"
            v-gl-tooltip.hover
            data-testid="cancel-auto-stop-button"
            :title="$options.i18n.cancelAutoStopButtonTitle"
            type="submit"
            icon="thumbtack"
          />
        </form>
        <gl-button
          v-if="shouldShowTerminalButton"
          data-testid="terminal-button"
          :href="terminalPath"
          icon="terminal"
        />
        <gl-button
          v-if="shouldShowExternalUrlButton"
          v-gl-tooltip.hover
          data-testid="external-url-button"
          :title="$options.i18n.externalButtonTitle"
          :href="environment.externalUrl"
          is-unsafe-link
          icon="external-link"
          target="_blank"
          >{{ $options.i18n.externalButtonText }}</gl-button
        >
        <gl-button v-if="canUpdateEnvironment" data-testid="edit-button" :href="updatePath">
          {{ $options.i18n.editButtonText }}
        </gl-button>
        <gl-button
          v-if="shouldShowStopButton"
          v-gl-modal-directive="'stop-environment-modal'"
          data-testid="stop-button"
          icon="stop"
          variant="danger"
        >
          {{ $options.i18n.stopButtonText }}
        </gl-button>
        <gl-button
          v-if="canDestroyEnvironment"
          v-gl-modal-directive="'delete-environment-modal'"
          data-testid="destroy-button"
          variant="danger"
        >
          {{ $options.i18n.deleteButtonText }}
        </gl-button>
      </div>
      <delete-environment-modal v-if="canDestroyEnvironment" :environment="environment" />
      <stop-environment-modal v-if="shouldShowStopButton" :environment="environment" />
    </header>

    <gl-truncate-text
      v-if="environment.descriptionHtml"
      :show-more-text="$options.i18n.showMoreText"
      class="gl-relative gl-mb-4"
    >
      <div
        ref="gfm-content"
        v-safe-html:[$options.safeHtmlConfig]="environment.descriptionHtml"
        class="md"
        data-testid="environment-description-content"
      ></div>
    </gl-truncate-text>
  </div>
</template>
