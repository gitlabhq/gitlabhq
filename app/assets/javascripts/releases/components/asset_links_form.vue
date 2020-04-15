<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import {
  GlSprintf,
  GlLink,
  GlFormGroup,
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlFormInput,
} from '@gitlab/ui';

export default {
  name: 'AssetLinksForm',
  components: { GlSprintf, GlLink, GlFormGroup, GlButton, GlIcon, GlFormInput },
  directives: { GlTooltip: GlTooltipDirective },
  computed: {
    ...mapState('detail', ['release', 'releaseAssetsDocsPath']),
    ...mapGetters('detail', ['validationErrors']),
  },
  created() {
    this.ensureAtLeastOneLink();
  },
  methods: {
    ...mapActions('detail', [
      'addEmptyAssetLink',
      'updateAssetLinkUrl',
      'updateAssetLinkName',
      'removeAssetLink',
    ]),
    onAddAnotherClicked() {
      this.addEmptyAssetLink();
    },
    onRemoveClicked(linkId) {
      this.removeAssetLink(linkId);
      this.ensureAtLeastOneLink();
    },
    onUrlInput(linkIdToUpdate, newUrl) {
      this.updateAssetLinkUrl({ linkIdToUpdate, newUrl });
    },
    onLinkTitleInput(linkIdToUpdate, newName) {
      this.updateAssetLinkName({ linkIdToUpdate, newName });
    },
    hasDuplicateUrl(link) {
      return Boolean(this.getLinkErrors(link).isDuplicate);
    },
    hasBadFormat(link) {
      return Boolean(this.getLinkErrors(link).isBadFormat);
    },
    hasEmptyUrl(link) {
      return Boolean(this.getLinkErrors(link).isUrlEmpty);
    },
    hasEmptyName(link) {
      return Boolean(this.getLinkErrors(link).isNameEmpty);
    },
    getLinkErrors(link) {
      return this.validationErrors.assets.links[link.id] || {};
    },
    isUrlValid(link) {
      return !this.hasDuplicateUrl(link) && !this.hasBadFormat(link) && !this.hasEmptyUrl(link);
    },
    isNameValid(link) {
      return !this.hasEmptyName(link);
    },

    /**
     * Make sure the form is never completely empty by adding an
     * empty row if the form contains 0 links
     */
    ensureAtLeastOneLink() {
      if (this.release.assets.links.length === 0) {
        this.addEmptyAssetLink();
      }
    },
  },
};
</script>

<template>
  <div class="d-flex flex-column release-assets-links-form">
    <h2 class="text-4">{{ __('Release assets') }}</h2>
    <p class="m-0">
      <gl-sprintf
        :message="
          __(
            'Add %{linkStart}assets%{linkEnd} to your Release. GitLab automatically includes read-only assets, like source code and release evidence.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link
            :href="releaseAssetsDocsPath"
            target="_blank"
            :aria-label="__('Release assets documentation')"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <h3 class="text-3">{{ __('Links') }}</h3>
    <p>
      {{
        __(
          'Point to any links you like: documentation, built binaries, or other related materials. These can be internal or external links from your GitLab instance. Duplicate URLs are not allowed.',
        )
      }}
    </p>
    <div
      v-for="(link, index) in release.assets.links"
      :key="link.id"
      class="row flex-column flex-sm-row align-items-stretch align-items-sm-start"
    >
      <gl-form-group
        class="url-field form-group col"
        :label="__('URL')"
        :label-for="`asset-url-${index}`"
      >
        <gl-form-input
          :id="`asset-url-${index}`"
          ref="urlInput"
          :value="link.url"
          type="text"
          class="form-control"
          :state="isUrlValid(link)"
          @change="onUrlInput(link.id, $event)"
        />
        <template #invalid-feedback>
          <span v-if="hasEmptyUrl(link)" class="invalid-feedback d-inline">
            {{ __('URL is required') }}
          </span>
          <span v-else-if="hasBadFormat(link)" class="invalid-feedback d-inline">
            <gl-sprintf
              :message="
                __(
                  'URL must start with %{codeStart}http://%{codeEnd}, %{codeStart}https://%{codeEnd}, or %{codeStart}ftp://%{codeEnd}',
                )
              "
            >
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
          </span>
          <span v-else-if="hasDuplicateUrl(link)" class="invalid-feedback d-inline">
            {{ __('This URL is already used for another link; duplicate URLs are not allowed') }}
          </span>
        </template>
      </gl-form-group>

      <gl-form-group
        class="link-title-field col"
        :label="__('Link title')"
        :label-for="`asset-link-name-${index}`"
      >
        <gl-form-input
          :id="`asset-link-name-${index}`"
          ref="nameInput"
          :value="link.name"
          type="text"
          class="form-control"
          :state="isNameValid(link)"
          @change="onLinkTitleInput(link.id, $event)"
        />
        <template v-slot:invalid-feedback>
          <span v-if="hasEmptyName(link)" class="invalid-feedback d-inline">
            {{ __('Link title is required') }}
          </span>
        </template>
      </gl-form-group>

      <div class="mb-5 mb-sm-3 mt-sm-4 col col-sm-auto">
        <gl-button
          v-gl-tooltip
          class="remove-button w-100"
          :aria-label="__('Remove asset link')"
          :title="__('Remove asset link')"
          @click="onRemoveClicked(link.id)"
        >
          <gl-icon class="mr-1 mr-sm-0 mb-1" :size="16" name="remove" />
          <span class="d-inline d-sm-none">{{ __('Remove asset link') }}</span>
        </gl-button>
      </div>
    </div>
    <gl-button
      ref="addAnotherLinkButton"
      variant="link"
      class="align-self-end mb-5 mb-sm-0"
      @click="onAddAnotherClicked"
    >
      {{ __('Add another link') }}
    </gl-button>
  </div>
</template>
