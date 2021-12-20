<script>
import { GlModal, GlSprintf, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlButton,
  },
  props: {
    selector: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      labelName: '',
      subjectName: '',
      destroyPath: '',
      modalId: uniqueId('modal-delete-label-'),
    };
  },
  mounted() {
    document.querySelectorAll(this.selector).forEach((button) => {
      button.addEventListener('click', (e) => {
        e.preventDefault();

        const { labelName, subjectName, destroyPath } = button.dataset;
        this.labelName = labelName;
        this.subjectName = subjectName;
        this.destroyPath = destroyPath;
        this.openModal();
      });
    });
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
};
</script>

<template>
  <gl-modal ref="modal" :modal-id="modalId">
    <template #modal-title>
      <gl-sprintf :message="__('Delete label: %{labelName}')">
        <template #labelName>
          {{ labelName }}
        </template>
      </gl-sprintf>
    </template>
    <gl-sprintf
      :message="
        __(
          `%{strongStart}${labelName}%{strongEnd} will be permanently deleted from ${subjectName}. This cannot be undone.`,
        )
      "
    >
      <template #strong="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
    <template #modal-footer>
      <gl-button category="secondary" @click="closeModal">{{ __('Cancel') }}</gl-button>
      <gl-button
        category="primary"
        variant="danger"
        :href="destroyPath"
        data-method="delete"
        data-testid="delete-button"
        >{{ __('Delete label') }}</gl-button
      >
    </template>
  </gl-modal>
</template>
