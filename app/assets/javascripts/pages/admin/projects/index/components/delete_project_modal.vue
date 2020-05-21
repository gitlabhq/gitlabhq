<script>
import { escape } from 'lodash';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    DeprecatedModal,
  },
  props: {
    deleteProjectUrl: {
      type: String,
      required: false,
      default: '',
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    csrfToken: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      enteredProjectName: '',
    };
  },
  computed: {
    title() {
      return sprintf(
        s__('AdminProjects|Delete Project %{projectName}?'),
        {
          projectName: `'${escape(this.projectName)}'`,
        },
        false,
      );
    },
    text() {
      return sprintf(
        s__(`AdminProjects|
          You’re about to permanently delete the project %{projectName}, its repository,
          and all related resources including issues, merge requests, etc..  Once you confirm and press
          %{strong_start}Delete project%{strong_end}, it cannot be undone or recovered.`),
        {
          projectName: `<strong>${escape(this.projectName)}</strong>`,
          strong_start: '<strong>',
          strong_end: '</strong>',
        },
        false,
      );
    },
    confirmationTextLabel() {
      return sprintf(
        s__('AdminUsers|To confirm, type %{projectName}'),
        {
          projectName: `<code>${escape(this.projectName)}</code>`,
        },
        false,
      );
    },
    primaryButtonLabel() {
      return s__('AdminProjects|Delete project');
    },
    canSubmit() {
      return this.enteredProjectName === this.projectName;
    },
  },
  methods: {
    onCancel() {
      this.enteredProjectName = '';
    },
    onSubmit() {
      this.$refs.form.submit();
      this.enteredProjectName = '';
    },
  },
};
</script>

<template>
  <deprecated-modal
    id="delete-project-modal"
    :title="title"
    :text="text"
    :primary-button-label="primaryButtonLabel"
    :submit-disabled="!canSubmit"
    kind="danger"
    @submit="onSubmit"
    @cancel="onCancel"
  >
    <template #body="props">
      <p v-html="props.text"></p>
      <p v-html="confirmationTextLabel"></p>
      <form ref="form" :action="deleteProjectUrl" method="post">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
        <input
          v-model="enteredProjectName"
          name="projectName"
          class="form-control"
          type="text"
          aria-labelledby="input-label"
          autocomplete="off"
        />
      </form>
    </template>
  </deprecated-modal>
</template>
