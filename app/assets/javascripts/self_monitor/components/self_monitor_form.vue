<script>
import { GlFormGroup, GlButton, GlModal, GlToast, GlToggle, GlLink, GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import { mapState, mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { helpPagePath } from '~/helpers/help_page_helper';
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
    GlLink,
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  formLabels: {
    createProject: __('Self-monitoring'),
  },
  data() {
    return {
      modalId: 'delete-self-monitor-modal',
      showDeprecationNotice: true,
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
    selfMonitoringDeprecationNotice() {
      return sprintf(
        s__(
          'SelfMonitoring|Self-monitoring was %{deprecation}deprecated%{link_end} in GitLab 14.9, and is %{removal}scheduled for removal%{link_end} in GitLab 16.0. For information on a possible replacement, %{opstrace}learn more about Opstrace%{link_end}.',
        ),
        {
          deprecation: `<a href="${this.deprecationPath}">`,
          removal: `<a href="https://gitlab.com/gitlab-org/gitlab/-/issues/348909">`,
          opstrace: `<a href="https://gitlab.com/groups/gitlab-org/-/epics/6976">`,
          link_end: `</a>`,
        },
        false,
      );
    },
    selfMonitoringFormText() {
      if (this.projectCreated) {
        return sprintf(
          s__(
            'SelfMonitoring|Self-monitoring is active. Use the %{projectLinkStart}self-monitoring project%{projectLinkEnd} to monitor the health of your instance.',
          ),
          {
            projectLinkStart: `<a href="${this.selfMonitorProjectFullUrl}">`,
            projectLinkEnd: '</a>',
          },
          false,
        );
      }

      return s__(
        'SelfMonitoring|Activate self-monitoring to create a project to use to monitor the health of your instance.',
      );
    },
    helpDocsPath() {
      return helpPagePath('administration/monitoring/gitlab_self_monitoring_project/index');
    },
    deprecationPath() {
      return helpPagePath('update/deprecations.md', { anchor: 'gitlab-self-monitoring-project' });
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
    hideDeprecationNotice() {
      this.showDeprecationNotice = false;
    },
  },
};
</script>
<template>
  <section class="settings no-animate js-self-monitoring-settings">
    <div class="settings-header">
      <h4
        class="js-section-header settings-title js-settings-toggle js-settings-toggle-trigger-only"
      >
        {{ s__('SelfMonitoring|Self-monitoring') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{ s__('SelfMonitoring|Activate or deactivate instance self-monitoring.') }}
        <gl-link :href="helpDocsPath">{{ __('Learn more.') }}</gl-link>
      </p>
    </div>
    <gl-alert
      v-if="showDeprecationNotice"
      class="gl-mb-3"
      :title="s__('SelfMonitoring|Deprecation notice')"
      :dismissible="true"
      variant="danger"
      @dismiss="hideDeprecationNotice"
    >
      <div v-safe-html="selfMonitoringDeprecationNotice"></div>
    </gl-alert>
    <div class="settings-content">
      <form name="self-monitoring-form">
        <p ref="selfMonitoringFormText" v-safe-html="selfMonitoringFormText"></p>
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
      :title="s__('SelfMonitoring|Deactivate self-monitoring?')"
      :modal-id="modalId"
      :ok-title="__('Delete self-monitoring project')"
      :cancel-title="__('Cancel')"
      ok-variant="danger"
      category="primary"
      @ok="deleteProject"
      @cancel="hideSelfMonitorModal"
    >
      <div>
        {{
          s__(
            'SelfMonitoring|Deactivating self-monitoring deletes the self-monitoring project. Are you sure you want to deactivate self-monitoring and delete the project?',
          )
        }}
      </div>
    </gl-modal>
  </section>
</template>
