<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlSkeletonLoader } from '@gitlab/ui';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import EditArea from '../components/edit_area.vue';
import EditHeader from '../components/edit_header.vue';
import SavedChangesMessage from '../components/saved_changes_message.vue';
import PublishToolbar from '../components/publish_toolbar.vue';
import InvalidContentMessage from '../components/invalid_content_message.vue';
import SubmitChangesError from '../components/submit_changes_error.vue';

export default {
  components: {
    RichContentEditor,
    EditArea,
    EditHeader,
    InvalidContentMessage,
    GlSkeletonLoader,
    SavedChangesMessage,
    PublishToolbar,
    SubmitChangesError,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState([
      'content',
      'isLoadingContent',
      'isSavingChanges',
      'isContentLoaded',
      'isSupportedContent',
      'returnUrl',
      'title',
      'submitChangesError',
      'savedContentMeta',
    ]),
    ...mapGetters(['contentChanged']),
  },
  mounted() {
    if (this.isSupportedContent) {
      this.loadContent();
    }
  },
  methods: {
    ...mapActions(['loadContent', 'setContent', 'submitChanges', 'dismissSubmitChangesError']),
  },
};
</script>
<template>
  <div class="d-flex justify-content-center h-100 pt-2">
    <!-- Success view -->
    <saved-changes-message
      v-if="savedContentMeta"
      class="w-75"
      :branch="savedContentMeta.branch"
      :commit="savedContentMeta.commit"
      :merge-request="savedContentMeta.mergeRequest"
      :return-url="returnUrl"
    />

    <!-- Main view -->
    <template v-else-if="isSupportedContent">
      <div v-if="isLoadingContent" class="w-50 h-50">
        <gl-skeleton-loader :width="500" :height="102">
          <rect width="500" height="16" rx="4" />
          <rect y="20" width="375" height="16" rx="4" />
          <rect x="380" y="20" width="120" height="16" rx="4" />
          <rect y="40" width="250" height="16" rx="4" />
          <rect x="255" y="40" width="150" height="16" rx="4" />
          <rect x="410" y="40" width="90" height="16" rx="4" />
        </gl-skeleton-loader>
      </div>
      <div v-if="isContentLoaded" class="d-flex flex-grow-1 flex-column">
        <submit-changes-error
          v-if="submitChangesError"
          class="w-75 align-self-center"
          :error="submitChangesError"
          @retry="submitChanges"
          @dismiss="dismissSubmitChangesError"
        />
        <edit-header class="w-75 align-self-center py-2" :title="title" />
        <rich-content-editor
          v-if="glFeatures.richContentEditor"
          class="w-75 gl-align-self-center"
          :value="content"
          @input="setContent"
        />
        <edit-area
          v-else
          class="w-75 h-100 shadow-none align-self-center"
          :value="content"
          @input="setContent"
        />
        <publish-toolbar
          :return-url="returnUrl"
          :saveable="contentChanged"
          :saving-changes="isSavingChanges"
          @submit="submitChanges"
        />
      </div>
    </template>

    <!-- Error view -->
    <invalid-content-message v-else class="w-75" />
  </div>
</template>
