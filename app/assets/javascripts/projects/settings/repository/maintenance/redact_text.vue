<script>
import { GlButton, GlDrawer, GlFormTextarea, GlSprintf, GlLink } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import { createAlert, VARIANT_WARNING } from '~/alert';
import replaceTextMutation from './graphql/mutations/replace_text.mutation.graphql';
import WarningModal from './warning_modal.vue';

const trackingMixin = InternalEvents.mixin();

const i18n = {
  redactText: s__('ProjectMaintenance|Redact text'),
  redactMatchingStrings: s__('ProjectMaintenance|Redact matching strings'),
  removed: s__('ProjectMaintenance|REMOVED'),
  description: s__(
    'ProjectMaintenance|Redact matching instances of text in the repository. Strings will be replaced with %{removed}.',
  ),
  warningHelpLink: s__('ProjectMaintenance|How does text redaction work?'),
  label: s__('ProjectMaintenance|Strings to redact'),
  helpText: s__(
    'ProjectMaintenance|Regex and glob patterns supported. Enter multiple entries on separate lines.',
  ),
  redactTextError: s__('ProjectMaintenance|Something went wrong while redacting text.'),
  scheduledRedactionSuccessAlertTitle: s__(
    'ProjectMaintenance|Text redaction removal is scheduled.',
  ),
  scheduledSuccessAlertContent: s__(
    'ProjectMaintenance|You will receive an email notification when the process is complete. To remove old versions from the repository, run housekeeping.',
  ),
  successAlertButtonText: s__('ProjectMaintenance|Go to housekeeping'),
  warningModalTitle: s__(
    'ProjectMaintenance|You are about to permanently redact text from this project.',
  ),
  warningModalPrimaryText: s__('ProjectMaintenance|Yes, redact matching strings'),
};

export default {
  i18n,
  DRAWER_Z_INDEX,
  components: { GlButton, GlDrawer, GlFormTextarea, GlSprintf, GlLink, WarningModal },
  redactTextWarningHelpLink: helpPagePath('/user/project/merge_requests/revert_changes', {
    anchor: 'redact-text-from-repository',
  }),
  mixins: [trackingMixin],
  inject: { projectPath: { default: '' }, housekeepingPath: { default: '' } },
  data() {
    return {
      isDrawerOpen: false,
      text: null,
      showConfirmationModal: false,
      isLoading: false,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    textArray() {
      return this.text?.split('\n') || [];
    },
    isValid() {
      return this.textArray.length;
    },
  },
  methods: {
    openDrawer() {
      this.isDrawerOpen = true;
    },
    closeDrawer() {
      this.text = null;
      this.isDrawerOpen = false;
    },
    redactText() {
      this.showConfirmationModal = true;
    },
    redactTextConfirm() {
      this.isLoading = true;
      this.trackEvent('click_redact_text_button_repository_settings');
      this.$apollo
        .mutate({
          mutation: replaceTextMutation,
          variables: {
            replacements: this.textArray,
            projectPath: this.projectPath,
          },
        })
        .then(({ data: { projectTextReplace: { errors } = {} } = {} }) => {
          this.isLoading = false;

          if (errors?.length) {
            this.handleError();
            return;
          }

          this.closeDrawer();
          this.generateSuccessAlert();
        })
        .catch(() => {
          this.isLoading = false;
          this.handleError();
        });
    },
    generateSuccessAlert() {
      createAlert({
        title: this.$options.i18n.scheduledRedactionSuccessAlertTitle,
        message: this.$options.i18n.scheduledSuccessAlertContent,
        variant: VARIANT_WARNING,
        primaryButton: {
          text: i18n.successAlertButtonText,
          clickHandler: () => this.navigateToHousekeeping(),
        },
      });
    },
    navigateToHousekeeping() {
      visitUrl(this.housekeepingPath);
    },
    handleError() {
      createAlert({ message: i18n.redactTextError, captureError: true });
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      class="gl-mb-6"
      category="secondary"
      variant="danger"
      data-testid="drawer-trigger"
      @click="openDrawer"
      >{{ $options.i18n.redactText }}</gl-button
    >

    <gl-drawer
      :header-height="getDrawerHeaderHeight"
      :open="isDrawerOpen"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDrawer"
    >
      <template #title>
        <h4 class="gl-m-0">{{ $options.i18n.redactText }}</h4>
      </template>

      <div>
        <p class="gl-text-subtle">
          <gl-sprintf :message="$options.i18n.description">
            <template #removed>
              <code>***{{ $options.i18n.removed }}***</code>
            </template>
          </gl-sprintf>
        </p>
        <label for="text">{{ $options.i18n.label }}</label>
        <gl-form-textarea
          id="text"
          v-model.trim="text"
          class="gl-mb-3 !gl-font-monospace"
          :disabled="isLoading"
          autofocus
        />

        <p class="gl-text-subtle">{{ $options.i18n.helpText }}</p>

        <gl-button
          data-testid="redact-text"
          variant="danger"
          :disabled="!isValid"
          :loading="isLoading"
          @click="redactText"
          >{{ $options.i18n.redactMatchingStrings }}</gl-button
        >
      </div>
    </gl-drawer>

    <warning-modal
      :visible="showConfirmationModal"
      :title="$options.i18n.warningModalTitle"
      :primary-text="$options.i18n.warningModalPrimaryText"
      :confirm-phrase="projectPath"
      :confirm-loading="isLoading"
      @confirm="redactTextConfirm"
      @hide="showConfirmationModal = false"
    >
      <gl-link :href="$options.redactTextWarningHelpLink" target="_blank">{{
        $options.i18n.warningHelpLink
      }}</gl-link>
    </warning-modal>
  </div>
</template>
