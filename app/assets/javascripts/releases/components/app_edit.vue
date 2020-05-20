<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlButton, GlFormInput, GlFormGroup } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, sprintf } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { BACK_URL_PARAM } from '~/releases/constants';
import { getParameterByName } from '~/lib/utils/common_utils';
import AssetLinksForm from './asset_links_form.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MilestoneCombobox from '~/milestones/project_milestone_combobox.vue';

export default {
  name: 'ReleaseEditApp',
  components: {
    GlFormInput,
    GlFormGroup,
    GlButton,
    MarkdownField,
    AssetLinksForm,
    MilestoneCombobox,
  },
  directives: {
    autofocusonshow,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState('detail', [
      'isFetchingRelease',
      'isUpdatingRelease',
      'fetchError',
      'markdownDocsPath',
      'markdownPreviewPath',
      'releasesPagePath',
      'updateReleaseApiDocsPath',
      'release',
      'newMilestonePath',
      'manageMilestonesPath',
      'projectId',
    ]),
    ...mapGetters('detail', ['isValid']),
    showForm() {
      return !this.isFetchingRelease && !this.fetchError;
    },
    subtitleText() {
      return sprintf(
        __(
          'Releases are based on Git tags. We recommend tags that use semantic versioning, for example %{codeStart}v1.0%{codeEnd}, %{codeStart}v2.0-pre%{codeEnd}.',
        ),
        {
          codeStart: '<code>',
          codeEnd: '</code>',
        },
        false,
      );
    },
    tagName() {
      return this.$store.state.detail.release.tagName;
    },
    tagNameHintText() {
      return sprintf(
        __(
          'Changing a Release tag is only supported via Releases API. %{linkStart}More information%{linkEnd}',
        ),
        {
          linkStart: `<a href="${escape(
            this.updateReleaseApiDocsPath,
          )}" target="_blank" rel="noopener noreferrer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    releaseTitle: {
      get() {
        return this.$store.state.detail.release.name;
      },
      set(title) {
        this.updateReleaseTitle(title);
      },
    },
    releaseNotes: {
      get() {
        return this.$store.state.detail.release.description;
      },
      set(notes) {
        this.updateReleaseNotes(notes);
      },
    },
    releaseMilestones: {
      get() {
        return this.$store.state.detail.release.milestones;
      },
      set(milestones) {
        this.updateReleaseMilestones(milestones);
      },
    },
    cancelPath() {
      return getParameterByName(BACK_URL_PARAM) || this.releasesPagePath;
    },
    showAssetLinksForm() {
      return this.glFeatures.releaseAssetLinkEditing;
    },
    isSaveChangesDisabled() {
      return this.isUpdatingRelease || !this.isValid;
    },
    milestoneComboboxExtraLinks() {
      return [
        {
          text: __('Create new'),
          url: this.newMilestonePath,
        },
        {
          text: __('Manage milestones'),
          url: this.manageMilestonesPath,
        },
      ];
    },
  },
  created() {
    this.fetchRelease();
  },
  methods: {
    ...mapActions('detail', [
      'fetchRelease',
      'updateRelease',
      'updateReleaseTitle',
      'updateReleaseNotes',
      'updateReleaseMilestones',
    ]),
  },
};
</script>
<template>
  <div class="d-flex flex-column">
    <p class="pt-3 js-subtitle-text" v-html="subtitleText"></p>
    <form v-if="showForm" @submit.prevent="updateRelease()">
      <gl-form-group>
        <div class="row">
          <div class="col-md-6 col-lg-5 col-xl-4">
            <label for="git-ref">{{ __('Tag name') }}</label>
            <gl-form-input
              id="git-ref"
              v-model="tagName"
              type="text"
              class="form-control"
              aria-describedby="tag-name-help"
              disabled
            />
          </div>
        </div>
        <div id="tag-name-help" class="form-text text-muted" v-html="tagNameHintText"></div>
      </gl-form-group>
      <gl-form-group>
        <label for="release-title">{{ __('Release title') }}</label>
        <gl-form-input
          id="release-title"
          ref="releaseTitleInput"
          v-model="releaseTitle"
          v-autofocusonshow
          autofocus
          type="text"
          class="form-control"
        />
      </gl-form-group>
      <gl-form-group class="w-50">
        <label>{{ __('Milestones') }}</label>
        <div class="d-flex flex-column col-md-6 col-sm-10 pl-0">
          <milestone-combobox
            v-model="releaseMilestones"
            :project-id="projectId"
            :extra-links="milestoneComboboxExtraLinks"
          />
        </div>
      </gl-form-group>
      <gl-form-group>
        <label for="release-notes">{{ __('Release notes') }}</label>
        <div class="bordered-box pr-3 pl-3">
          <markdown-field
            :can-attach-file="true"
            :markdown-preview-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocsPath"
            :add-spacing-classes="false"
            class="prepend-top-10 append-bottom-10"
          >
            <template #textarea>
              <textarea
                id="release-notes"
                v-model="releaseNotes"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="__('Release notes')"
                :placeholder="__('Write your release notes or drag your files here…')"
                @keydown.meta.enter="updateRelease()"
                @keydown.ctrl.enter="updateRelease()"
              ></textarea>
            </template>
          </markdown-field>
        </div>
      </gl-form-group>

      <asset-links-form v-if="showAssetLinksForm" />

      <div class="d-flex pt-3">
        <gl-button
          class="mr-auto js-no-auto-disable"
          category="primary"
          variant="success"
          type="submit"
          :aria-label="__('Save changes')"
          :disabled="isSaveChangesDisabled"
          >{{ __('Save changes') }}</gl-button
        >
        <gl-button :href="cancelPath" class="js-cancel-button">{{ __('Cancel') }}</gl-button>
      </div>
    </form>
  </div>
</template>
