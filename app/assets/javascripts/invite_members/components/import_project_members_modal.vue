<script>
import { GlFormGroup, GlModal, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { importProjectMembers } from '~/api/projects_api';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import { s__, __, sprintf } from '~/locale';
import eventHub from '../event_hub';
import {
  displaySuccessfulInvitationAlert,
  reloadOnInvitationSuccess,
} from '../utils/trigger_successful_invite_alert';
import { PROJECT_SELECT_LABEL_ID } from '../constants';
import ProjectSelect from './project_select.vue';

export default {
  name: 'ImportProjectMembersModal',
  components: {
    GlFormGroup,
    GlModal,
    GlSprintf,
    ProjectSelect,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    reloadPageOnSubmit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      projectToBeImported: {},
      invalidFeedbackMessage: '',
      isLoading: false,
    };
  },
  computed: {
    modalIntro() {
      return sprintf(this.$options.i18n.modalIntro, {
        name: this.projectName,
      });
    },
    importDisabled() {
      return Object.keys(this.projectToBeImported).length === 0;
    },
    validationState() {
      return this.invalidFeedbackMessage === '' ? null : false;
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.modalPrimaryButton,
        attributes: {
          variant: 'confirm',
          disabled: this.importDisabled,
          loading: this.isLoading,
        },
      };
    },
    actionCancel() {
      return { text: this.$options.i18n.modalCancelButton };
    },
  },
  mounted() {
    if (this.reloadPageOnSubmit) {
      displaySuccessfulInvitationAlert();
    }

    eventHub.$on('openProjectMembersModal', () => {
      this.openModal();
    });
  },
  methods: {
    openModal() {
      this.$root.$emit(BV_SHOW_MODAL, this.$options.modalId);
    },
    closeModal() {
      this.$root.$emit(BV_HIDE_MODAL, this.$options.modalId);
    },
    resetFields() {
      this.invalidFeedbackMessage = '';
      this.projectToBeImported = {};
    },
    submitImport(e) {
      // We never want to hide when submitting
      e.preventDefault();

      this.isLoading = true;
      return importProjectMembers(this.projectId, this.projectToBeImported.id)
        .then(this.onInviteSuccess)
        .catch(this.showErrorAlert)
        .finally(() => {
          this.isLoading = false;
          this.projectToBeImported = {};
        });
    },
    onInviteSuccess() {
      if (this.reloadPageOnSubmit) {
        reloadOnInvitationSuccess();
      } else {
        this.showToastMessage();
      }
    },
    showToastMessage() {
      this.$toast.show(this.$options.i18n.successMessage, this.$options.toastOptions);
      this.closeModal();
    },
    showErrorAlert() {
      this.invalidFeedbackMessage = this.$options.i18n.defaultError;
    },
  },
  toastOptions() {
    return {
      onComplete: () => {
        this.projectToBeImported = {};
      },
    };
  },
  i18n: {
    projectLabel: __('Project'),
    modalTitle: s__('ImportAProjectModal|Import members from another project'),
    modalIntro: s__(
      "ImportAProjectModal|You're importing members to the %{strongStart}%{name}%{strongEnd} project.",
    ),
    modalHelpText: s__(
      'ImportAProjectModal|Only project members (not group members) are imported, and they get the same permissions as the project you import from.',
    ),
    modalPrimaryButton: s__('ImportAProjectModal|Import project members'),
    modalCancelButton: __('Cancel'),
    defaultError: s__('ImportAProjectModal|Unable to import project members'),
    successMessage: s__('ImportAProjectModal|Successfully imported'),
  },
  projectSelectLabelId: PROJECT_SELECT_LABEL_ID,
  modalId: uniqueId('import-a-project-modal-'),
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    size="sm"
    :title="$options.i18n.modalTitle"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    @primary="submitImport"
    @hidden="resetFields"
  >
    <p ref="modalIntro">
      <gl-sprintf :message="modalIntro">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group
      :invalid-feedback="invalidFeedbackMessage"
      :state="validationState"
      data-testid="form-group"
      label-cols="auto"
      label-class="gl-pt-3!"
      :label="$options.i18n.projectLabel"
      :label-for="$options.projectSelectLabelId"
    >
      <project-select v-model="projectToBeImported" />
    </gl-form-group>
    <p>{{ $options.i18n.modalHelpText }}</p>
  </gl-modal>
</template>
