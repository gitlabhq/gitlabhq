<script>
import { GlButton, GlFormGroup, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { importProjectMembers } from '~/api/projects_api';
import { s__, __, sprintf } from '~/locale';
import ProjectSelect from './project_select.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlModal,
    GlSprintf,
    ProjectSelect,
  },
  directives: {
    GlModal: GlModalDirective,
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
  },
  methods: {
    submitImport() {
      this.isLoading = true;
      return importProjectMembers(this.projectId, this.projectToBeImported.id)
        .then(this.showToastMessage)
        .catch(this.showErrorAlert)
        .finally(() => {
          this.isLoading = false;
          this.projectToBeImported = {};
        });
    },
    closeModal() {
      this.invalidFeedbackMessage = '';

      this.$refs.modal.hide();
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
    buttonText: s__('ImportAProjectModal|Import from a project'),
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
  projectSelectLabelId: 'project-select',
  modalId: uniqueId('import-a-project-modal-'),
  formClasses: 'gl-mt-3 gl-sm-w-auto gl-w-full',
  buttonClasses: 'gl-w-full',
};
</script>

<template>
  <form :class="$options.formClasses">
    <gl-button v-gl-modal="$options.modalId" :class="$options.buttonClasses" variant="default">{{
      $options.i18n.buttonText
    }}</gl-button>

    <gl-modal
      ref="modal"
      :modal-id="$options.modalId"
      size="sm"
      :title="$options.i18n.modalTitle"
      ok-variant="danger"
      footer-class="gl-bg-gray-10 gl-p-5"
    >
      <div>
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
        >
          <label :id="$options.projectSelectLabelId" class="col-form-label">{{
            $options.i18n.projectLabel
          }}</label>
          <project-select v-model="projectToBeImported" />
        </gl-form-group>
        <p>{{ $options.i18n.modalHelpText }}</p>
      </div>
      <template #modal-footer>
        <div
          class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-m-0"
        >
          <gl-button data-testid="cancel-button" @click="closeModal">
            {{ $options.i18n.modalCancelButton }}
          </gl-button>
          <div class="gl-mr-3"></div>
          <gl-button
            :disabled="importDisabled"
            :loading="isLoading"
            variant="success"
            data-testid="import-button"
            @click="submitImport"
            >{{ $options.i18n.modalPrimaryButton }}</gl-button
          >
        </div>
      </template>
    </gl-modal>
  </form>
</template>
