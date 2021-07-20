<script>
/* eslint-disable vue/no-v-html */
import { GlFormGroup, GlButton, GlModal, GlToast, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import { mapState, mapActions } from 'vuex';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';

Vue.use(GlToast);

export default {
  components: {
    GlFormGroup,
    GlButton,
    GlModal,
    GlToggle,
  },
  formLabels: {
    createProject: __('Create Project'),
  },
  data() {
    return {
      modalId: 'delete-self-monitor-modal',
    };
  },
  computed: {
    ...mapState('selfMonitoring', [
      'projectEnabled',
      'projectCreated',
      'showAlert',
      'projectPath',
      'loading',
      'alertContent',
    ]),
    selfMonitorEnabled: {
      get() {
        return this.projectEnabled;
      },
      set(projectEnabled) {
        this.setSelfMonitor(projectEnabled);
      },
    },
    selfMonitorProjectFullUrl() {
      return `${getBaseURL()}/${this.projectPath}`;
    },
    selfMonitoringFormText() {
      if (this.projectCreated) {
        return sprintf(
          s__(
            'SelfMonitoring|Enabling this feature creates a %{projectLinkStart}project%{projectLinkEnd} that can be used to monitor the health of your instance.',
          ),
          {
            projectLinkStart: `<a href="${this.selfMonitorProjectFullUrl}">`,
            projectLinkEnd: '</a>',
          },
          false,
        );
      }

      return s__(
        'SelfMonitoring|Enabling this feature creates a project that can be used to monitor the health of your instance.',
      );
    },
  },
  watch: {
    selfMonitorEnabled() {
      this.saveChangesSelfMonitorProject();
    },
    showAlert() {
      let toastOptions = {
        onComplete: () => {
          this.resetAlert();
        },
      };

      if (this.showAlert) {
        if (this.alertContent.actionName && this.alertContent.actionName.length > 0) {
          toastOptions = {
            ...toastOptions,
            action: {
              text: this.alertContent.actionText,
              onClick: (_, toastObject) => {
                this[this.alertContent.actionName]();
                toastObject.hide();
              },
            },
          };
        }
        this.$toast.show(this.alertContent.message, toastOptions);
      }
    },
  },
  methods: {
    ...mapActions('selfMonitoring', [
      'setSelfMonitor',
      'createProject',
      'deleteProject',
      'resetAlert',
    ]),
    hideSelfMonitorModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.modalId);
      this.setSelfMonitor(true);
    },
    showSelfMonitorModal() {
      this.$root.$emit(BV_SHOW_MODAL, this.modalId);
    },
    saveChangesSelfMonitorProject() {
      if (this.projectCreated && !this.projectEnabled) {
        this.showSelfMonitorModal();
      } else if (!this.projectCreated && !this.loading) {
        this.createProject();
      }
    },
    viewSelfMonitorProject() {
      visitUrl(this.selfMonitorProjectFullUrl);
    },
  },
};
</script>
<template>
  <section class="settings no-animate js-self-monitoring-settings">
    <div class="settings-header">
      <h4 class="js-section-header">
        {{ s__('SelfMonitoring|Self monitoring') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{ s__('SelfMonitoring|Enable or disable instance self monitoring') }}
      </p>
    </div>
    <div class="settings-content">
      <form name="self-monitoring-form">
        <p ref="selfMonitoringFormText" v-html="selfMonitoringFormText"></p>
        <gl-form-group>
          <gl-toggle
            v-model="selfMonitorEnabled"
            :is-loading="loading"
            :label="$options.formLabels.createProject"
          />
        </gl-form-group>
      </form>
    </div>
    <gl-modal
      :title="s__('SelfMonitoring|Disable self monitoring?')"
      :modal-id="modalId"
      :ok-title="__('Delete project')"
      :cancel-title="__('Cancel')"
      ok-variant="danger"
      category="primary"
      @ok="deleteProject"
      @cancel="hideSelfMonitorModal"
    >
      <div>
        {{
          s__(
            'SelfMonitoring|Disabling this feature will delete the self monitoring project. Are you sure you want to delete the project?',
          )
        }}
      </div>
    </gl-modal>
  </section>
</template>
