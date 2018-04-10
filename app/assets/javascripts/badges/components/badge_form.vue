<script>
import _ from 'underscore';
import { mapActions, mapState } from 'vuex';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import createEmptyBadge from '../empty_badge';
import Badge from './badge.vue';

const badgePreviewDelayInMilliseconds = 1500;

export default {
  name: 'BadgeForm',
  components: {
    Badge,
    LoadingButton,
    LoadingIcon,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'badgeInAddForm',
      'badgeInEditForm',
      'docsUrl',
      'isRendering',
      'isSaving',
      'renderedBadge',
    ]),
    badge() {
      if (this.isEditing) {
        return this.badgeInEditForm;
      }

      return this.badgeInAddForm;
    },
    canSubmit() {
      return (
        this.badge !== null &&
        this.badge.imageUrl &&
        this.badge.imageUrl.trim() !== '' &&
        this.badge.linkUrl &&
        this.badge.linkUrl.trim() !== '' &&
        !this.isSaving
      );
    },
    helpText() {
      const placeholders = ['project_path', 'project_id', 'default_branch', 'commit_sha']
        .map(placeholder => `<code>%{${placeholder}}</code>`)
        .join(', ');
      return sprintf(
        s__('Badges|The %{docsLinkStart}variables%{docsLinkEnd} GitLab supports: %{placeholders}'),
        {
          docsLinkEnd: '</a>',
          docsLinkStart: `<a href="${_.escape(this.docsUrl)}">`,
          placeholders,
        },
        false,
      );
    },
    renderedImageUrl() {
      return this.renderedBadge ? this.renderedBadge.renderedImageUrl : '';
    },
    renderedLinkUrl() {
      return this.renderedBadge ? this.renderedBadge.renderedLinkUrl : '';
    },
    imageUrl: {
      get() {
        return this.badge ? this.badge.imageUrl : '';
      },
      set(imageUrl) {
        const badge = this.badge || createEmptyBadge();
        this.updateBadgeInForm({
          ...badge,
          imageUrl,
        });
      },
    },
    linkUrl: {
      get() {
        return this.badge ? this.badge.linkUrl : '';
      },
      set(linkUrl) {
        const badge = this.badge || createEmptyBadge();
        this.updateBadgeInForm({
          ...badge,
          linkUrl,
        });
      },
    },
    submitButtonLabel() {
      if (this.isEditing) {
        return s__('Badges|Save changes');
      }
      return s__('Badges|Add badge');
    },
  },
  methods: {
    ...mapActions(['addBadge', 'renderBadge', 'saveBadge', 'stopEditing', 'updateBadgeInForm']),
    debouncedPreview: _.debounce(function preview() {
      this.renderBadge();
    }, badgePreviewDelayInMilliseconds),
    onCancel() {
      this.stopEditing();
    },
    onSubmit() {
      if (!this.canSubmit) {
        return Promise.resolve();
      }

      if (this.isEditing) {
        return this.saveBadge()
          .then(() => {
            createFlash(s__('Badges|The badge was saved.'), 'notice');
          })
          .catch(error => {
            createFlash(
              s__('Badges|Saving the badge failed, please check the entered URLs and try again.'),
            );
            throw error;
          });
      }

      return this.addBadge()
        .then(() => {
          createFlash(s__('Badges|A new badge was added.'), 'notice');
        })
        .catch(error => {
          createFlash(
            s__('Badges|Adding the badge failed, please check the entered URLs and try again.'),
          );
          throw error;
        });
    },
  },
  badgeImageUrlPlaceholder:
    'https://example.gitlab.com/%{project_path}/badges/%{default_branch}/<badge>.svg',
  badgeLinkUrlPlaceholder: 'https://example.gitlab.com/%{project_path}',
};
</script>

<template>
  <form
    class="prepend-top-default append-bottom-default"
    @submit.prevent.stop="onSubmit"
  >
    <div class="form-group">
      <label for="badge-link-url">{{ s__('Badges|Link') }}</label>
      <input
        id="badge-link-url"
        type="text"
        class="form-control"
        v-model="linkUrl"
        :placeholder="$options.badgeLinkUrlPlaceholder"
        @input="debouncedPreview"
      />
      <span
        class="help-block"
        v-html="helpText"
      ></span>
    </div>

    <div class="form-group">
      <label for="badge-image-url">{{ s__('Badges|Badge image URL') }}</label>
      <input
        id="badge-image-url"
        type="text"
        class="form-control"
        v-model="imageUrl"
        :placeholder="$options.badgeImageUrlPlaceholder"
        @input="debouncedPreview"
      />
      <span
        class="help-block"
        v-html="helpText"
      ></span>
    </div>

    <div class="form-group">
      <label for="badge-preview">{{ s__('Badges|Badge image preview') }}</label>
      <badge
        id="badge-preview"
        v-show="renderedBadge && !isRendering"
        :image-url="renderedImageUrl"
        :link-url="renderedLinkUrl"
      />
      <p v-show="isRendering">
        <loading-icon
          :inline="true"
        />
      </p>
      <p
        v-show="!renderedBadge && !isRendering"
        class="disabled-content"
      >{{ s__('Badges|No image to preview') }}</p>
    </div>

    <div class="row-content-block">
      <loading-button
        type="submit"
        container-class="btn btn-success"
        :disabled="!canSubmit"
        :loading="isSaving"
        :label="submitButtonLabel"
      />
      <button
        class="btn btn-cancel"
        type="button"
        v-if="isEditing"
        @click="onCancel"
      >{{ __('Cancel') }}</button>
    </div>
  </form>
</template>
