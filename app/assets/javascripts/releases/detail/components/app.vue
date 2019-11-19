<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlFormInput, GlFormGroup } from '@gitlab/ui';
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  name: 'ReleaseDetailApp',
  components: {
    GlFormInput,
    GlFormGroup,
    GlButton,
    MarkdownField,
  },
  directives: {
    autofocusonshow,
  },
  computed: {
    ...mapState([
      'isFetchingRelease',
      'fetchError',
      'markdownDocsPath',
      'markdownPreviewPath',
      'releasesPagePath',
      'updateReleaseApiDocsPath',
    ]),
    showForm() {
      return !this.isFetchingRelease && !this.fetchError;
    },
    subtitleText() {
      return sprintf(
        __(
          'Releases are based on Git tags. We recommend naming tags that fit within semantic versioning, for example %{codeStart}v1.0%{codeEnd}, %{codeStart}v2.0-pre%{codeEnd}.',
        ),
        {
          codeStart: '<code>',
          codeEnd: '</code>',
        },
        false,
      );
    },
    tagName() {
      return this.$store.state.release.tagName;
    },
    tagNameHintText() {
      return sprintf(
        __(
          'Changing a Release tag is only supported via Releases API. %{linkStart}More information%{linkEnd}',
        ),
        {
          linkStart: `<a href="${_.escape(
            this.updateReleaseApiDocsPath,
          )}" target="_blank" rel="noopener noreferrer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    releaseTitle: {
      get() {
        return this.$store.state.release.name;
      },
      set(title) {
        this.updateReleaseTitle(title);
      },
    },
    releaseNotes: {
      get() {
        return this.$store.state.release.description;
      },
      set(notes) {
        this.updateReleaseNotes(notes);
      },
    },
  },
  created() {
    this.fetchRelease();
  },
  methods: {
    ...mapActions([
      'fetchRelease',
      'updateRelease',
      'updateReleaseTitle',
      'updateReleaseNotes',
      'navigateToReleasesPage',
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
            <textarea
              id="release-notes"
              slot="textarea"
              v-model="releaseNotes"
              class="note-textarea js-gfm-input js-autosize markdown-area"
              dir="auto"
              data-supports-quick-actions="false"
              :aria-label="__('Release notes')"
              :placeholder="__('Write your release notes or drag your files here…')"
              @keydown.meta.enter="updateRelease()"
              @keydown.ctrl.enter="updateRelease()"
            >
            </textarea>
          </markdown-field>
        </div>
      </gl-form-group>

      <div class="d-flex pt-3">
        <gl-button
          class="mr-auto js-submit-button"
          variant="success"
          type="submit"
          :aria-label="__('Save changes')"
        >
          {{ __('Save changes') }}
        </gl-button>
        <gl-button
          class="js-cancel-button"
          variant="default"
          type="button"
          :aria-label="__('Cancel')"
          @click="navigateToReleasesPage()"
        >
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </form>
  </div>
</template>
