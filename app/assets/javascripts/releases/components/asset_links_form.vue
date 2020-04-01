<script>
import { mapState, mapActions } from 'vuex';
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
  },
  created() {
    this.addEmptyAssetLink();
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
    },
    onUrlInput(linkIdToUpdate, newUrl) {
      this.updateAssetLinkUrl({ linkIdToUpdate, newUrl });
    },
    onLinkTitleInput(linkIdToUpdate, newName) {
      this.updateAssetLinkName({ linkIdToUpdate, newName });
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
          'Point to any links you like: documentation, built binaries, or other related materials. These can be internal or external links from your GitLab instance.',
        )
      }}
    </p>
    <div
      v-for="(link, index) in release.assets.links"
      :key="link.id"
      class="d-flex flex-column flex-sm-row align-items-stretch align-items-sm-end"
    >
      <gl-form-group
        class="url-field form-group flex-grow-1 mr-sm-4"
        :label="__('URL')"
        :label-for="`asset-url-${index}`"
      >
        <gl-form-input
          :id="`asset-url-${index}`"
          :value="link.url"
          type="text"
          class="form-control"
          @change="onUrlInput(link.id, $event)"
        />
      </gl-form-group>

      <gl-form-group
        class="link-title-field flex-grow-1 mr-sm-4"
        :label="__('Link title')"
        :label-for="`asset-link-name-${index}`"
      >
        <gl-form-input
          :id="`asset-link-name-${index}`"
          :value="link.name"
          type="text"
          class="form-control"
          @change="onLinkTitleInput(link.id, $event)"
        />
      </gl-form-group>

      <gl-button
        v-gl-tooltip
        class="mb-5 mb-sm-3 flex-grow-0 flex-shrink-0 remove-button"
        :aria-label="__('Remove asset link')"
        :title="__('Remove asset link')"
        @click="onRemoveClicked(link.id)"
      >
        <gl-icon class="m-0" name="remove" />
        <span class="d-inline d-sm-none">{{ __('Remove asset link') }}</span>
      </gl-button>
    </div>
    <gl-button variant="link" class="align-self-end mb-5 mb-sm-0" @click="onAddAnotherClicked">
      {{ __('Add another link') }}
    </gl-button>
  </div>
</template>
