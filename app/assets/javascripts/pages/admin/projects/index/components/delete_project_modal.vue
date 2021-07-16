<script>
import { GlSafeHtmlDirective as SafeHtml, GlModal } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  directives: {
    SafeHtml,
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
          and all related resources, including issues and merge requests. Once you confirm and press
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
    canSubmit() {
      return this.enteredProjectName === this.projectName;
    },
    primaryProps() {
      return {
        text: s__('Delete project'),
        attributes: [{ variant: 'danger' }, { category: 'primary' }, { disabled: !this.canSubmit }],
      };
    },
  },
  methods: {
    onCancel() {
      this.enteredProjectName = '';
    },
    onSubmit() {
      if (!this.canSubmit) {
        return;
      }
      this.$refs.form.submit();
      this.enteredProjectName = '';
    },
  },
  cancelProps: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="delete-project-modal"
    :title="title"
    :action-primary="primaryProps"
    :action-cancel="$options.cancelProps"
    :ok-disabled="!canSubmit"
    @primary="onSubmit"
    @cancel="onCancel"
  >
    <p v-safe-html="text"></p>
    <p v-safe-html="confirmationTextLabel"></p>
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
  </gl-modal>
</template>
