<script>
import { GlButton, GlForm, GlFormFields, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isValidURL } from '~/lib/utils/url_utility';
import { createAlert, VARIANT_INFO } from '~/alert';
import { s__ } from '~/locale';
import createEmptyBadge from '../empty_badge';
import Badge from './badge.vue';
import SupportedPlaceholders from './supported_placeholders.vue';

const badgePreviewDelayInMilliseconds = 1500;

export default {
  name: 'BadgeForm',
  components: {
    Badge,
    GlButton,
    GlForm,
    GlFormFields,
    GlSprintf,
    GlLoadingIcon,
    SupportedPlaceholders,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isEditing: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['badgeInAddForm', 'badgeInEditForm', 'isRendering', 'isSaving', 'renderedBadge']),
    badge() {
      if (this.isEditing) {
        return this.badgeInEditForm;
      }

      return this.badgeInAddForm;
    },
    renderedImageUrl() {
      return this.renderedBadge ? this.renderedBadge.renderedImageUrl : '';
    },
    renderedLinkUrl() {
      return this.renderedBadge ? this.renderedBadge.renderedLinkUrl : '';
    },
  },
  watch: {
    'badge.linkUrl': function badgeLinkUrlWatcher() {
      this.debouncedPreview();
    },
    'badge.imageUrl': function badgeImageUrlWatcher() {
      this.debouncedPreview();
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
    onFormFieldsInput(fieldValues) {
      const badge = this.badge || createEmptyBadge();
      this.updateBadgeInForm({
        ...badge,
        ...fieldValues,
      });
    },
    onSubmit() {
      if (this.isEditing) {
        return this.saveBadge()
          .then(() => {
            createAlert({
              message: s__('Badges|Badge saved.'),
              variant: VARIANT_INFO,
            });
          })
          .catch(() => {
            createAlert({
              message: s__(
                'Badges|Saving the badge failed, please check the entered URLs and try again.',
              ),
            });
          });
      }

      return this.addBadge()
        .then(() => {
          createAlert({
            message: s__('Badges|New badge added.'),
            variant: VARIANT_INFO,
          });
          this.$emit('close-add-form');
        })
        .catch(() => {
          createAlert({
            message: s__('Badges|Failed to add new badge. Check the URLs, then try again.'),
          });
        });
    },
    closeForm() {
      this.updateBadgeInForm({});
      this.$emit('close-add-form');
    },
  },
  fields: {
    name: {
      label: s__('Badges|Name'),
      validators: [formValidators.required(s__('Badges|Badge name is required.'))],
      inputAttrs: {
        width: {
          lg: 'xl',
        },
        'data-testid': 'badge-name-field',
      },
    },
    linkUrl: {
      label: s__('Badges|Link'),
      validators: [
        formValidators.required(s__('Badges|Badge link is required.')),
        formValidators.factory(s__('Badges|Badge link is invalid.'), (value) => isValidURL(value)),
      ],
      inputAttrs: {
        width: {
          lg: 'xl',
        },
        'data-testid': 'badge-link-url-field',
      },
    },
    imageUrl: {
      label: s__('Badges|Badge image URL'),
      validators: [
        formValidators.required(s__('Badges|Badge image URL is required.')),
        formValidators.factory(s__('Badges|Badge image URL is invalid.'), (value) =>
          isValidURL(value),
        ),
      ],
      inputAttrs: {
        width: {
          lg: 'xl',
        },
        'data-testid': 'badge-image-url-field',
      },
    },
  },
  formId: 'new-badge-form',
  i18n: {
    example: s__('Badges|Example: %{exampleUrl}'),
    supportedVariables: s__(
      'Badges|Supported %{docsLinkStart}variables%{docsLinkEnd}: %{placeholders}',
    ),
  },
  linkExampleUrl: 'https://example.gitlab.com/%{project_path}',
  imageExampleUrl:
    'https://example.gitlab.com/%{project_path}/badges/%{default_branch}/pipeline.svg',
};
</script>

<template>
  <gl-form :id="$options.formId">
    <gl-form-fields
      :values="badge"
      :form-id="$options.formId"
      :fields="$options.fields"
      @input="onFormFieldsInput"
      @submit="onSubmit"
    >
      <template #group(linkUrl)-label-description>
        <supported-placeholders />
      </template>

      <template #group(linkUrl)-description>
        <gl-sprintf :message="$options.i18n.example">
          <template #exampleUrl>{{ $options.linkExampleUrl }}</template>
        </gl-sprintf>
      </template>

      <template #group(imageUrl)-label-description>
        <supported-placeholders />
      </template>

      <template #group(imageUrl)-description>
        <gl-sprintf :message="$options.i18n.example">
          <template #exampleUrl>{{ $options.imageExampleUrl }}</template>
        </gl-sprintf>
      </template>
    </gl-form-fields>
    <div class="gl-mb-5">
      <p class="gl-mb-3 gl-mt-0 gl-font-bold gl-text-strong">
        {{ s__('Badges|Badge image preview') }}
      </p>
      <gl-loading-icon v-if="isRendering" size="sm" :inline="true" />
      <badge v-else-if="renderedBadge" :image-url="renderedImageUrl" :link-url="renderedLinkUrl" />
      <p v-else class="gl-m-0 gl-text-subtle">
        {{ s__('Badges|No image to preview') }}
      </p>
    </div>

    <div v-if="!isEditing" class="gl-flex gl-gap-3" data-testid="action-buttons">
      <gl-button
        :loading="isSaving"
        class="js-no-auto-disable"
        type="submit"
        variant="confirm"
        category="primary"
        data-testid="add-badge-button"
      >
        {{ s__('Badges|Add badge') }}
      </gl-button>
      <gl-button type="button" @click="closeForm">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
