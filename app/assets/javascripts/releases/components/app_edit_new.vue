<script>
import { GlButton, GlFormInput, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { isSameOriginUrl, getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MilestoneCombobox from '~/milestones/components/milestone_combobox.vue';
import { BACK_URL_PARAM } from '~/releases/constants';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import AssetLinksForm from './asset_links_form.vue';
import TagField from './tag_field.vue';

export default {
  name: 'ReleaseEditNewApp',
  components: {
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlSprintf,
    MarkdownField,
    AssetLinksForm,
    MilestoneCombobox,
    TagField,
  },
  computed: {
    ...mapState('editNew', [
      'isFetchingRelease',
      'isUpdatingRelease',
      'fetchError',
      'markdownDocsPath',
      'markdownPreviewPath',
      'releasesPagePath',
      'release',
      'newMilestonePath',
      'manageMilestonesPath',
      'projectId',
      'groupId',
      'groupMilestonesAvailable',
    ]),
    ...mapGetters('editNew', ['isValid', 'isExistingRelease']),
    showForm() {
      return Boolean(!this.isFetchingRelease && !this.fetchError && this.release);
    },
    releaseTitle: {
      get() {
        return this.$store.state.editNew.release.name;
      },
      set(title) {
        this.updateReleaseTitle(title);
      },
    },
    releaseNotes: {
      get() {
        return this.$store.state.editNew.release.description;
      },
      set(notes) {
        this.updateReleaseNotes(notes);
      },
    },
    releaseMilestones: {
      get() {
        return this.$store.state.editNew.release.milestones;
      },
      set(milestones) {
        this.updateReleaseMilestones(milestones);
      },
    },
    cancelPath() {
      const backUrl = getParameterByName(BACK_URL_PARAM);

      if (isSameOriginUrl(backUrl)) {
        return backUrl;
      }

      return this.releasesPagePath;
    },
    saveButtonLabel() {
      return this.isExistingRelease ? __('Save changes') : __('Create release');
    },
    isFormSubmissionDisabled() {
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
  async mounted() {
    await this.initializeRelease();

    // Focus the first non-disabled input or button element
    this.$el.querySelector('input:enabled, button:enabled').focus();
  },
  methods: {
    ...mapActions('editNew', [
      'initializeRelease',
      'saveRelease',
      'updateReleaseTitle',
      'updateReleaseNotes',
      'updateReleaseMilestones',
    ]),
    submitForm() {
      if (!this.isFormSubmissionDisabled) {
        this.saveRelease();
      }
    },
  },
};
</script>
<template>
  <div class="d-flex flex-column">
    <p class="pt-3 js-subtitle-text">
      <gl-sprintf
        :message="
          __(
            'Releases are based on Git tags. We recommend tags that use semantic versioning, for example %{codeStart}v1.0.0%{codeEnd}, %{codeStart}v2.1.0-pre%{codeEnd}.',
          )
        "
      >
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
    <form v-if="showForm" class="js-quick-submit" @submit.prevent="submitForm">
      <tag-field />
      <gl-form-group>
        <label for="release-title">{{ __('Release title') }}</label>
        <gl-form-input
          id="release-title"
          ref="releaseTitleInput"
          v-model="releaseTitle"
          type="text"
          class="form-control"
        />
      </gl-form-group>
      <gl-form-group class="w-50" data-testid="milestones-field">
        <label>{{ __('Milestones') }}</label>
        <div class="d-flex flex-column col-md-6 col-sm-10 pl-0">
          <milestone-combobox
            v-model="releaseMilestones"
            :project-id="projectId"
            :group-id="groupId"
            :group-milestones-available="groupMilestonesAvailable"
            :extra-links="milestoneComboboxExtraLinks"
          />
        </div>
      </gl-form-group>
      <gl-form-group data-testid="release-notes">
        <label for="release-notes">{{ __('Release notes') }}</label>
        <div class="bordered-box pr-3 pl-3">
          <markdown-field
            :can-attach-file="true"
            :markdown-preview-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocsPath"
            :add-spacing-classes="false"
            :textarea-value="releaseNotes"
            class="gl-mt-3 gl-mb-3"
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
              ></textarea>
            </template>
          </markdown-field>
        </div>
      </gl-form-group>

      <asset-links-form />

      <div class="d-flex pt-3">
        <gl-button
          class="mr-auto js-no-auto-disable"
          category="primary"
          variant="success"
          type="submit"
          :disabled="isFormSubmissionDisabled"
          data-testid="submit-button"
        >
          {{ saveButtonLabel }}
        </gl-button>
        <gl-button :href="cancelPath" class="js-cancel-button">{{ __('Cancel') }}</gl-button>
      </div>
    </form>
  </div>
</template>
