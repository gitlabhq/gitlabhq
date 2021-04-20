<script>
import {
  GlSprintf,
  GlLink,
  GlFormGroup,
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlFormInput,
  GlFormSelect,
} from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { DEFAULT_ASSET_LINK_TYPE, ASSET_LINK_TYPE } from '../constants';

export default {
  name: 'AssetLinksForm',
  components: {
    GlSprintf,
    GlLink,
    GlFormGroup,
    GlButton,
    GlIcon,
    GlFormInput,
    GlFormSelect,
  },
  directives: { GlTooltip: GlTooltipDirective },
  computed: {
    ...mapState('editNew', ['release', 'releaseAssetsDocsPath']),
    ...mapGetters('editNew', ['validationErrors']),
  },
  created() {
    this.ensureAtLeastOneLink();
  },
  methods: {
    ...mapActions('editNew', [
      'addEmptyAssetLink',
      'updateAssetLinkUrl',
      'updateAssetLinkName',
      'updateAssetLinkType',
      'removeAssetLink',
    ]),
    onAddAnotherClicked() {
      this.addEmptyAssetLink();
    },
    onRemoveClicked(linkId) {
      this.removeAssetLink(linkId);
      this.ensureAtLeastOneLink();
    },
    updateUrl(link, newUrl) {
      this.updateAssetLinkUrl({ linkIdToUpdate: link.id, newUrl });
    },
    updateName(link, newName) {
      this.updateAssetLinkName({ linkIdToUpdate: link.id, newName });
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
  typeOptions: [
    { value: ASSET_LINK_TYPE.IMAGE, text: s__('ReleaseAssetLinkType|Image') },
    { value: ASSET_LINK_TYPE.PACKAGE, text: s__('ReleaseAssetLinkType|Package') },
    { value: ASSET_LINK_TYPE.RUNBOOK, text: s__('ReleaseAssetLinkType|Runbook') },
    { value: ASSET_LINK_TYPE.OTHER, text: s__('ReleaseAssetLinkType|Other') },
  ],
  defaultTypeOptionValue: DEFAULT_ASSET_LINK_TYPE,
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
      class="row flex-column flex-sm-row align-items-stretch align-items-sm-start no-gutters"
    >
      <gl-form-group
        class="url-field form-group col pr-sm-2"
        :label="__('URL')"
        :label-for="`asset-url-${index}`"
      >
        <gl-form-input
          :id="`asset-url-${index}`"
          ref="urlInput"
          :value="link.url"
          type="text"
          class="form-control"
          name="asset-url"
          :state="isUrlValid(link)"
          @change="updateUrl(link, $event)"
          @keydown.ctrl.enter="updateUrl(link, $event.target.value)"
          @keydown.meta.enter="updateUrl(link, $event.target.value)"
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
        class="link-title-field col px-sm-2"
        :label="__('Link title')"
        :label-for="`asset-link-name-${index}`"
      >
        <gl-form-input
          :id="`asset-link-name-${index}`"
          ref="nameInput"
          :value="link.name"
          type="text"
          class="form-control"
          name="asset-link-name"
          :state="isNameValid(link)"
          @change="updateName(link, $event)"
          @keydown.ctrl.enter="updateName(link, $event.target.value)"
          @keydown.meta.enter="updateName(link, $event.target.value)"
        />
        <template #invalid-feedback>
          <span v-if="hasEmptyName(link)" class="invalid-feedback d-inline">
            {{ __('Link title is required') }}
          </span>
        </template>
      </gl-form-group>

      <gl-form-group
        class="link-type-field col-auto px-sm-2"
        :label="__('Type')"
        :label-for="`asset-type-${index}`"
      >
        <gl-form-select
          :id="`asset-type-${index}`"
          ref="typeSelect"
          :value="link.linkType || $options.defaultTypeOptionValue"
          class="form-control pr-4"
          name="asset-type"
          :options="$options.typeOptions"
          @change="updateAssetLinkType({ linkIdToUpdate: link.id, newType: $event })"
        />
      </gl-form-group>

      <div class="mb-5 mb-sm-3 mt-sm-4 col col-sm-auto pl-sm-2">
        <gl-button
          v-gl-tooltip
          class="remove-button w-100 form-control"
          :aria-label="__('Remove asset link')"
          :title="__('Remove asset link')"
          @click="onRemoveClicked(link.id)"
        >
          <div class="d-flex">
            <gl-icon class="mr-1 mr-sm-0" :size="16" name="remove" />
            <span class="d-inline d-sm-none">{{ __('Remove asset link') }}</span>
          </div>
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
