<script>
import $ from 'jquery';
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import GlModal from '~/vue_shared/components/gl_modal.vue';

export default {
  components: {
    Icon,
    GlModal,
  },
  directives: {
    tooltip,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalId() {
      return `discard-file-${this.path}`;
    },
    modalTitle() {
      return `Discard changes to ${this.path}?`;
    },
  },
  methods: {
    ...mapActions(['stageChange', 'discardFileChanges']),
    showDiscardModal() {
      $(document.getElementById(this.modalId)).modal('show');
    },
  },
};
</script>

<template>
  <div
    v-once
    class="multi-file-discard-btn"
  >
    <button
      v-tooltip
      :aria-label="__('Stage changes')"
      :title="__('Stage changes')"
      type="button"
      class="btn btn-blank d-flex align-items-center"
      data-container="body"
      data-boundary="viewport"
      data-placement="bottom"
      @click.stop.prevent="stageChange(path)"
    >
      <icon
        :size="16"
        name="mobile-issue-close"
        class="ml-auto mr-auto"
      />
    </button>
    <button
      v-tooltip
      :aria-label="__('Discard changes')"
      :title="__('Discard changes')"
      type="button"
      class="btn btn-blank d-flex align-items-center"
      data-container="body"
      data-boundary="viewport"
      data-placement="bottom"
      @click.stop.prevent="showDiscardModal"
    >
      <icon
        :size="16"
        name="remove"
        class="ml-auto mr-auto"
      />
    </button>
    <gl-modal
      :id="modalId"
      :header-title-text="modalTitle"
      :footer-primary-button-text="__('Discard changes')"
      footer-primary-button-variant="danger"
      @submit="discardFileChanges(path)"
    >
      {{ __("You will loose all changes you've made to this file. This action cannot be undone.") }}
    </gl-modal>
  </div>
</template>
