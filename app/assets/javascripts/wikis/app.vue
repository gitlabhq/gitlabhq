<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WikiHeader from './components/wiki_header.vue';
import WikiContent from './components/wiki_content.vue';
import WikiForm from './components/wiki_form.vue';
import WikiAlert from './components/wiki_alert.vue';
import WikiNotesApp from './wiki_notes/components/wiki_notes_app.vue';

export default {
  components: {
    GlAlert,
    WikiHeader,
    WikiContent,
    WikiForm,
    WikiAlert,
    WikiNotesApp,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    isEditingPath: { default: false },
    isPageHistorical: { default: null },
    wikiUrl: { default: null },
    historyUrl: { default: null },
    error: { default: null },
    pagePersisted: { default: false },
  },
  i18n: {
    alertText: s__('WikiHistoricalPage|This is an old version of this page.'),
    alertPrimaryButton: s__('WikiHistoricalPage|Go to most recent version'),
    alertSecondaryButton: s__('WikiHistoricalPage|Browse history'),
  },
  data() {
    return {
      hasEnteredEditMode: false,
    };
  },
  computed: {
    isEditing() {
      return this.isEditingPath || this.hasEnteredEditMode;
    },
    showWikiNotes() {
      return !this.isCustomSidebar && (!this.isEditing || this.pagePersisted);
    },
    showWikiHeader() {
      if (this.glFeatures.wikiImmersiveEditor) {
        return !this.isEditing;
      }
      return !this.hasEnteredEditMode;
    },
    isCustomSidebar() {
      return this.wikiUrl.endsWith('_sidebar');
    },
  },
  watch: {
    hasEnteredEditMode() {
      const url = new URL(window.location);

      if (this.hasEnteredEditMode) {
        url.searchParams.set('edit', 'true');
      } else {
        url.searchParams.delete('edit');
      }

      window.history.pushState({}, '', url);
    },
  },
  mounted() {
    this.checkEditingMode();
    window.addEventListener('popstate', this.checkEditingMode);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkEditingMode);
  },
  methods: {
    setEditingMode(value) {
      this.hasEnteredEditMode = value;
    },
    checkEditingMode() {
      const url = new URL(window.location);

      if (url.searchParams.has('edit')) {
        this.setEditingMode(true);
      } else {
        this.setEditingMode(false);
      }
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
    <wiki-header v-if="showWikiHeader" @is-editing="setEditingMode" />
    <wiki-form v-if="isEditing" @is-editing="setEditingMode" />
    <wiki-content v-else :is-editing="isEditing" />
    <wiki-notes-app v-if="showWikiNotes" />
  </div>
</template>
