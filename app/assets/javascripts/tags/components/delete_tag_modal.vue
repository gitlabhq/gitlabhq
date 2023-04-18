<script>
import { GlButton, GlFormInput, GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import { sprintf, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  csrf,
  components: {
    GlModal,
    GlButton,
    GlFormInput,
    GlSprintf,
    GlAlert,
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
      this.$refs.form.submit();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
  },
  i18n: {
    modalTitle: s__('TagsPage|Delete tag. Are you ABSOLUTELY SURE?'),
    modalTitleProtectedTag: s__('TagsPage|Delete protected tag. Are you ABSOLUTELY SURE?'),
    modalMessage: s__(
      "TagsPage|You're about to permanently delete the tag %{strongStart}%{tagName}.%{strongEnd}",
    ),
    modalMessageProtectedTag: s__(
      "TagsPage|You're about to permanently delete the protected tag %{strongStart}%{tagName}.%{strongEnd}",
    ),
    undoneWarning: s__(
      'TagsPage|After you confirm and select %{strongStart}%{buttonText},%{strongEnd} you cannot recover this tag.',
    ),
    cancelButtonText: s__('TagsPage|Cancel, keep tag'),
    confirmationText: s__(
      'TagsPage|Deleting the %{strongStart}%{tagName}%{strongEnd} tag cannot be undone. Are you sure?',
    ),
    confirmationTextProtectedTag: s__('TagsPage|Please type the following to confirm:'),
    deleteButtonText: s__('TagsPage|Yes, delete tag'),
    deleteButtonTextProtectedTag: s__('TagsPage|Yes, delete protected tag'),
  },
};
</script>

<template>
  <gl-modal ref="modal" size="sm" :modal-id="modalId" :title="title">
    <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
      <div data-testid="modal-message">
        <gl-sprintf :message="message">
          <template #strong="{ content }">
            <strong> {{ content }} </strong>
          </template>
        </gl-sprintf>
      </div>
    </gl-alert>

    <form ref="form" :action="path" method="post">
      <div v-if="isProtected" class="gl-mt-4">
        <p>
          <gl-sprintf :message="undoneWarning">
            <template #strong="{ content }">
              <strong> {{ content }} </strong>
            </template>
          </gl-sprintf>
        </p>
        <p>
          <gl-sprintf :message="$options.i18n.confirmationTextProtectedTag">
            <template #strong="{ content }">
              {{ content }}
            </template>
          </gl-sprintf>
          <code class="gl-white-space-pre-wrap"> {{ tagName }} </code>
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
      <div v-else>
        <p class="gl-mt-4">
          <gl-sprintf :message="confirmationText">
            <template #strong="{ content }">
              <strong>
                {{ content }}
              </strong>
            </template>
          </gl-sprintf>
        </p>
      </div>

      <input ref="method" type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </form>

    <template #modal-footer>
      <div class="gl-display-flex gl-flex-direction-row gl-justify-content-end gl-flex-wrap gl-m-0">
        <gl-button data-testid="delete-tag-cancel-button" @click="closeModal">
          {{ $options.i18n.cancelButtonText }}
        </gl-button>
        <div class="gl-mr-3"></div>
        <gl-button
          ref="deleteTagButton"
          :disabled="deleteButtonDisabled"
          variant="danger"
          data-qa-selector="delete_tag_confirmation_button"
          data-testid="delete-tag-confirmation-button"
          @click="submitForm"
          >{{ buttonText }}</gl-button
        >
      </div>
    </template>
  </gl-modal>
</template>
