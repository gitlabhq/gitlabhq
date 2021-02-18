<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import SharedDeleteButton from './shared/delete_button.vue';

export default {
  components: {
    GlSprintf,
    GlAlert,
    SharedDeleteButton,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  strings: {
    alertTitle: __('You are about to permanently delete this project'),
    alertBody: __(
      'Once a project is permanently deleted, it %{strongStart}cannot be recovered%{strongEnd}. Permanently deleting this project will %{strongStart}immediately delete%{strongEnd} its repositories and %{strongStart}all related resources%{strongEnd}, including issues, merge requests etc.',
    ),
    modalBody: __(
      "This action cannot be undone. You will lose this project's repository and all related resources, including issues, merge requests, etc.",
    ),
  },
};
</script>

<template>
  <shared-delete-button v-bind="{ confirmPhrase, formPath }">
    <template #modal-body>
      <gl-alert
        class="gl-mb-5"
        variant="danger"
        :title="$options.strings.alertTitle"
        :dismissible="false"
      >
        <gl-sprintf :message="$options.strings.alertBody">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>
      <p>{{ $options.strings.modalBody }}</p>
    </template>
  </shared-delete-button>
</template>
