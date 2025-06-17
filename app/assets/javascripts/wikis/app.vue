<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import WikiHeader from './components/wiki_header.vue';
import WikiContent from './components/wiki_content.vue';
import WikiEditForm from './components/wiki_form.vue';
import WikiAlert from './components/wiki_alert.vue';
import eventHub, { EVENT_EDIT_WIKI_DONE, EVENT_EDIT_WIKI_START } from './event_hub';

export default {
  components: {
    GlAlert,
    WikiHeader,
    WikiContent,
    WikiEditForm,
    WikiAlert,
  },
  inject: {
    isEditingPath: { default: null },
    isPageHistorical: { default: null },
    wikiUrl: { default: null },
    historyUrl: { default: null },
    error: { default: null },
  },
  i18n: {
    alertText: s__('WikiHistoricalPage|This is an old version of this page.'),
    alertPrimaryButton: s__('WikiHistoricalPage|Go to most recent version'),
    alertSecondaryButton: s__('WikiHistoricalPage|Browse history'),
  },
  data() {
    return {
      isEditing: false,
    };
  },
  watch: {
    isEditing() {
      const url = new URL(window.location);

      if (this.isEditing) {
        url.searchParams.set('edit', 'true');
        eventHub.$emit(EVENT_EDIT_WIKI_START);
      } else {
        url.searchParams.delete('edit');
        eventHub.$emit(EVENT_EDIT_WIKI_DONE);
      }

      window.history.pushState({}, '', url);
    },
  },
  mounted() {
    const url = new URL(window.location);

    if (url.searchParams.has('edit')) {
      this.setEditingMode(true);
    }
  },
  methods: {
    setEditingMode(value) {
      this.isEditing = value;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="isPageHistorical"
      :dismissible="false"
      variant="warning"
      class="gl-mt-5"
      :primary-button-text="$options.i18n.alertPrimaryButton"
      :primary-button-link="wikiUrl"
      :secondary-button-text="$options.i18n.alertSecondaryButton"
      :secondary-button-link="historyUrl"
    >
      {{ $options.i18n.alertText }}
    </gl-alert>
    <wiki-alert v-if="error" :error="error" :wiki-page-path="wikiUrl" class="gl-mt-5" />
    <wiki-header v-if="!isEditing" @is-editing="setEditingMode" />
    <wiki-edit-form v-if="isEditingPath || isEditing" @is-editing="setEditingMode" />
    <wiki-content v-else :is-editing="isEditing" />
  </div>
</template>
