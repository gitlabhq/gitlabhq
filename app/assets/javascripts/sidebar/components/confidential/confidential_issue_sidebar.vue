<script>
import { __ } from '~/locale';
import Flash from '~/flash';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '~/sidebar/event_hub';
import editForm from './edit_form.vue';
import { trackEvent } from 'ee_else_ce/event_tracking/issue_sidebar';

export default {
  components: {
    editForm,
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    isConfidential: {
      required: true,
      type: Boolean,
    },
    isEditable: {
      required: true,
      type: Boolean,
    },
    service: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      edit: false,
    };
  },
  computed: {
    confidentialityIcon() {
      return this.isConfidential ? 'eye-slash' : 'eye';
    },
    tooltipLabel() {
      return this.isConfidential ? __('Confidential') : __('Not confidential');
    },
  },
  created() {
    eventHub.$on('closeConfidentialityForm', this.toggleForm);
  },
  beforeDestroy() {
    eventHub.$off('closeConfidentialityForm', this.toggleForm);
  },
  methods: {
    toggleForm() {
      this.edit = !this.edit;
    },
    onEditClick() {
      this.toggleForm();

      trackEvent('click_edit_button', 'confidentiality');
    },
    updateConfidentialAttribute(confidential) {
      this.service
        .update('issue', { confidential })
        .then(() => window.location.reload())
        .catch(() => {
          Flash(__('Something went wrong trying to change the confidentiality of this issue'));
        });
    },
  },
};
</script>

<template>
  <div class="block issuable-sidebar-item confidentiality">
    <div
      v-tooltip
      :title="tooltipLabel"
      class="sidebar-collapsed-icon"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      @click="toggleForm"
    >
      <icon :name="confidentialityIcon" aria-hidden="true" />
    </div>
    <div class="title hide-collapsed">
      {{ __('Confidentiality') }}
      <a
        v-if="isEditable"
        class="float-right confidential-edit"
        href="#"
        @click.prevent="onEditClick"
      >
        {{ __('Edit') }}
      </a>
    </div>
    <div class="value sidebar-item-value hide-collapsed">
      <editForm
        v-if="edit"
        :is-confidential="isConfidential"
        :update-confidential-attribute="updateConfidentialAttribute"
      />
      <div v-if="!isConfidential" class="no-value sidebar-item-value">
        <icon :size="16" name="eye" aria-hidden="true" class="sidebar-item-icon inline" />
        {{ __('Not confidential') }}
      </div>
      <div v-else class="value sidebar-item-value hide-collapsed">
        <icon
          :size="16"
          name="eye-slash"
          aria-hidden="true"
          class="sidebar-item-icon inline is-active"
        />
        {{ __('This issue is confidential') }}
      </div>
    </div>
  </div>
</template>
