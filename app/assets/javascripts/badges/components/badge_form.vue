<script>
import { GlLoadingIcon, GlFormInput, GlFormGroup, GlButton } from '@gitlab/ui';
import { escape, debounce } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { createAlert, VARIANT_INFO } from '~/alert';
import { s__, sprintf } from '~/locale';
import createEmptyBadge from '../empty_badge';
import { PLACEHOLDERS } from '../constants';
import Badge from './badge.vue';

const badgePreviewDelayInMilliseconds = 1500;

export default {
  name: 'BadgeForm',
  components: {
    Badge,
    GlButton,
    GlLoadingIcon,
    GlFormInput,
    GlFormGroup,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: true,
    },
    inModal: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      wasValidated: false,
    };
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
    helpText() {
      const placeholders = PLACEHOLDERS.map((placeholder) => `<code>%{${placeholder}}</code>`).join(
        ', ',
      );
      return sprintf(
        s__('Badges|Supported %{docsLinkStart}variables%{docsLinkEnd}: %{placeholders}'),
        {
          docsLinkEnd: '</a>',
          docsLinkStart: `<a href="${escape(this.docsUrl)}">`,
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
    name: {
      get() {
        return this.badge ? this.badge.name : '';
      },
      set(name) {
        const badge = this.badge || createEmptyBadge();
        this.updateBadgeInForm({
          ...badge,
          name,
        });
      },
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
    badgeImageUrlExample() {
      const exampleUrl =
        'https://example.gitlab.com/%{project_path}/badges/%{default_branch}/pipeline.svg';
      return sprintf(s__('Badges|Example: %{exampleUrl}'), {
        exampleUrl,
      });
    },
    badgeLinkUrlExample() {
      const exampleUrl = 'https://example.gitlab.com/%{project_path}';
      return sprintf(s__('Badges|Example: %{exampleUrl}'), {
        exampleUrl,
      });
    },
    cancelButtonType() {
      return this.isEditing ? 'button' : 'reset';
    },
    saveText() {
      return this.isEditing ? s__('Badges|Save changes') : s__('Badges|Add badge');
    },
  },
  mounted() {
    // declared here to make it cancel-able
    this.debouncedPreview = debounce(function search() {
      this.renderBadge();
    }, badgePreviewDelayInMilliseconds);
  },
  methods: {
    ...mapActions(['addBadge', 'renderBadge', 'saveBadge', 'stopEditing', 'updateBadgeInForm']),
    updatePreview() {
      this.debouncedPreview();
    },
    onSubmit() {
      this.debouncedPreview.cancel();
      this.renderBadge();

      const form = this.$el;
      if (!form.checkValidity()) {
        this.wasValidated = true;
        return Promise.resolve();
      }

      if (this.isEditing) {
        return this.saveBadge()
          .then(() => {
            createAlert({
              message: s__('Badges|Badge saved.'),
              variant: VARIANT_INFO,
            });
            this.wasValidated = false;
          })
          .catch((error) => {
            createAlert({
              message: s__(
                'Badges|Saving the badge failed, please check the entered URLs and try again.',
              ),
            });
            throw error;
          });
      }

      return this.addBadge()
        .then(() => {
          createAlert({
            message: s__('Badges|New badge added.'),
            variant: VARIANT_INFO,
          });
          this.wasValidated = false;
          this.$emit('close-add-form');
        })
        .catch((error) => {
          createAlert({
            message: s__('Badges|Failed to add new badge. Check the URLs, then try again.'),
          });
          throw error;
        });
    },
    closeForm() {
      this.$refs.form.reset();
      this.$emit('close-add-form');
    },
    handleCancel() {
      if (this.isEditing) {
        this.stopEditing();
      } else {
        this.closeForm();
      }
    },
  },
  safeHtmlConfig: { ALLOW_TAGS: ['a', 'code'] },
};
</script>

<template>
  <form
    ref="form"
    :class="{ 'was-validated': wasValidated }"
    class="gl-mt-3 gl-mb-3 needs-validation"
    novalidate
    @submit.prevent.stop="onSubmit"
  >
    <gl-form-group :label="s__('Badges|Name')" label-for="badge-name" class="gl-max-w-48">
      <gl-form-input id="badge-name" v-model="name" data-testid="badge-name-field" />
    </gl-form-group>

    <div class="form-group">
      <label for="badge-link-url" class="label-bold">{{ s__('Badges|Link') }}</label>
      <p v-safe-html:[$options.safeHtmlConfig]="helpText"></p>
      <input
        id="badge-link-url"
        v-model="linkUrl"
        data-testid="badge-link-url-field"
        type="URL"
        class="form-control gl-form-input gl-max-w-80"
        required
        @input="updatePreview"
      />
      <div class="invalid-feedback">{{ s__('Badges|Enter a valid URL') }}</div>
      <span class="form-text text-muted">{{ badgeLinkUrlExample }}</span>
    </div>

    <div class="form-group">
      <label for="badge-image-url" class="label-bold">{{ s__('Badges|Badge image URL') }}</label>
      <p v-safe-html:[$options.safeHtmlConfig]="helpText"></p>
      <input
        id="badge-image-url"
        v-model="imageUrl"
        data-testid="badge-image-url-field"
        type="URL"
        class="form-control gl-form-input gl-max-w-80"
        required
        @input="updatePreview"
      />
      <div class="invalid-feedback">{{ s__('Badges|Enter a valid URL') }}</div>
      <span class="form-text text-muted">{{ badgeImageUrlExample }}</span>
    </div>

    <div class="form-group">
      <label for="badge-preview">{{ s__('Badges|Badge image preview') }}</label>
      <badge
        v-show="renderedBadge && !isRendering"
        id="badge-preview"
        :image-url="renderedImageUrl"
        :link-url="renderedLinkUrl"
      />
      <p v-show="isRendering">
        <gl-loading-icon size="sm" :inline="true" />
      </p>
      <p v-show="!renderedBadge && !isRendering" class="gl-text-subtle">
        {{ s__('Badges|No image to preview') }}
      </p>
    </div>

    <div v-if="!inModal" class="form-group" data-testid="action-buttons">
      <gl-button
        :loading="isSaving"
        type="submit"
        variant="confirm"
        category="primary"
        data-testid="add-badge-button"
        class="gl-mr-3"
      >
        {{ saveText }}
      </gl-button>
      <gl-button :type="cancelButtonType" @click="handleCancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
