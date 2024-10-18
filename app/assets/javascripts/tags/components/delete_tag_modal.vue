<script>
import { GlButton, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import { sprintf } from '~/locale';
import eventHub from '../event_hub';
import { I18N_DELETE_TAG_MODAL } from '../constants';

export default {
  csrf,
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
  },
  data() {
    return {
      isProtected: false,
      tagName: '',
      path: '',
      enteredTagName: '',
      modalId: 'delete-tag-modal',
    };
  },
  computed: {
    title() {
      const modalTitle = this.isProtected
        ? this.$options.i18n.modalTitleProtectedTag
        : this.$options.i18n.modalTitle;

      return sprintf(modalTitle, { tagName: this.tagName });
    },
    message() {
      const modalMessage = this.isProtected
        ? this.$options.i18n.modalMessageProtectedTag
        : this.$options.i18n.modalMessage;

      return sprintf(modalMessage, { tagName: this.tagName });
    },
    undoneWarning() {
      return sprintf(this.$options.i18n.undoneWarning, {
        buttonText: this.buttonText,
      });
    },
    confirmationText() {
      return sprintf(this.$options.i18n.confirmationText, {
        tagName: this.tagName,
      });
    },
    buttonText() {
      return this.isProtected
        ? this.$options.i18n.deleteButtonTextProtectedTag
        : this.$options.i18n.deleteButtonText;
    },
    tagNameConfirmed() {
      return this.enteredTagName === this.tagName;
    },
    deleteButtonDisabled() {
      return this.isProtected && !this.tagNameConfirmed;
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
    for (const btn of document.querySelectorAll('.js-delete-tag-button')) {
      btn.addEventListener('click', this.deleteTagBtnListener.bind(this, btn));
    }
  },
  destroyed() {
    eventHub.$off('openModal', this.openModal);
    for (const btn of document.querySelectorAll('.js-delete-tag-button')) {
      btn.removeEventListener('click', this.deleteTagBtnListener.bind(this, btn));
    }
  },
  methods: {
    deleteTagBtnListener(btn) {
      return this.openModal({
        ...btn.dataset,
        isProtected: parseBoolean(btn.dataset.isProtected),
      });
    },
    openModal({ isProtected, tagName, path }) {
      this.enteredTagName = '';
      this.isProtected = isProtected;
      this.tagName = tagName;
      this.path = path;

      this.$refs.modal.show();
    },
    submitForm() {
      if (!this.deleteButtonDisabled) {
        this.$refs.form.submit();
      }
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
  i18n: I18N_DELETE_TAG_MODAL,
};
</script>

<template>
  <gl-modal ref="modal" size="sm" :modal-id="modalId" :title="title">
    <div data-testid="modal-message">
      <gl-sprintf :message="message">
        <template #strong="{ content }">
          <strong> {{ content }} </strong>
        </template>
      </gl-sprintf>
    </div>
    <p class="gl-mt-4">
      <gl-sprintf :message="confirmationText">
        <template #strong="{ content }">
          <strong>
            {{ content }}
          </strong>
        </template>
      </gl-sprintf>
    </p>

    <form ref="form" :action="path" method="post" @submit.prevent="submitForm">
      <div v-if="isProtected" class="gl-mt-4">
        <p>
          <gl-sprintf :message="$options.i18n.confirmationTextProtectedTag">
            <template #strong="{ content }">
              {{ content }}
            </template>
          </gl-sprintf>
          <code> {{ tagName }} </code>
          <gl-form-input
            v-model="enteredTagName"
            name="delete_tag_input"
            type="text"
            class="gl-mt-4"
            aria-labelledby="input-label"
            autocomplete="off"
          />
        </p>
      </div>

      <input ref="method" type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </form>

    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-flex-row gl-flex-wrap gl-justify-end">
        <gl-button data-testid="delete-tag-cancel-button" @click="closeModal">
          {{ $options.i18n.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          ref="deleteTagButton"
          :disabled="deleteButtonDisabled"
          variant="danger"
          data-testid="delete-tag-confirmation-button"
          @click="submitForm"
          >{{ buttonText }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
