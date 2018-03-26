<script>
  import _ from 'underscore';
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
        return sprintf(s__('AdminProjects|Delete Project %{projectName}?'),
          {
            projectName: `'${_.escape(this.projectName)}'`,
          },
          false,
        );
      },
      text() {
        return sprintf(s__(`AdminProjects|
          You’re about to permanently delete the project %{projectName}, its repository,
          and all related resources including issues, merge requests, etc..  Once you confirm and press
          %{strong_start}Delete project%{strong_end}, it cannot be undone or recovered.`),
          {
            projectName: `<strong>${_.escape(this.projectName)}</strong>`,
            strong_start: '<strong>',
            strong_end: '</strong>',
          },
          false,
        );
      },
      confirmationTextLabel() {
        return sprintf(s__('AdminUsers|To confirm, type %{projectName}'),
          {
            projectName: `<code>${_.escape(this.projectName)}</code>`,
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
    kind="danger"
    :primary-button-label="primaryButtonLabel"
    :submit-disabled="!canSubmit"
    @submit="onSubmit"
    @cancel="onCancel"
  >
    <template
      slot="body"
      slot-scope="props"
    >
      <p v-html="props.text"></p>
      <p v-html="confirmationTextLabel"></p>
      <form
        ref="form"
        :action="deleteProjectUrl"
        method="post"
      >
        <input
          ref="method"
          type="hidden"
          name="_method"
          value="delete"
        />
        <input
          type="hidden"
          name="authenticity_token"
          :value="csrfToken"
        />
        <input
          name="projectName"
          class="form-control"
          type="text"
          v-model="enteredProjectName"
          aria-labelledby="input-label"
          autocomplete="off"
        />
      </form>
    </template>
  </deprecated-modal>
</template>
