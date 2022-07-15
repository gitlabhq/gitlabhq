<script>
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import { resourceLinksI18n } from '../constants';
import AddIssuableResourceLinkForm from './add_issuable_resource_link_form.vue';

export default {
  name: 'ResourceLinksBlock',
  components: {
    GlLink,
    GlButton,
    GlIcon,
    AddIssuableResourceLinkForm,
  },
  i18n: resourceLinksI18n,
  props: {
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    canAddResourceLinks: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isFormVisible: false,
      isSubmitting: false,
    };
  },
  computed: {
    badgeLabel() {
      return 0;
    },
    hasBody() {
      return this.isFormVisible;
    },
  },
  methods: {
    async toggleResourceLinkForm() {
      this.isFormVisible = !this.isFormVisible;
    },
    hideResourceLinkForm() {
      this.isFormVisible = false;
    },
  },
};
</script>

<template>
  <div id="resource-links" class="gl-mt-5">
    <div class="card card-slim gl-overflow-hidden">
      <div
        :class="{ 'panel-empty-heading border-bottom-0': !hasBody }"
        class="card-header gl-display-flex gl-justify-content-space-between"
      >
        <h3
          class="card-title h5 position-relative gl-my-0 gl-display-flex gl-align-items-center gl-h-7"
        >
          <gl-link
            id="user-content-resource-links"
            class="anchor position-absolute gl-text-decoration-none"
            href="#resource-links"
            aria-hidden="true"
          />
          <slot name="header-text">{{ $options.i18n.headerText }}</slot>
          <gl-link
            :href="helpPath"
            target="_blank"
            class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
            data-testid="help-link"
            :aria-label="$options.i18n.helpText"
          >
            <gl-icon name="question" :size="12" />
          </gl-link>

          <div class="gl-display-inline-flex">
            <div class="gl-display-inline-flex gl-mx-5">
              <span class="gl-display-inline-flex gl-align-items-center">
                <gl-icon name="link" class="gl-mr-2 gl-text-gray-500" />
                {{ badgeLabel }}
              </span>
            </div>
            <gl-button
              v-if="canAddResourceLinks"
              icon="plus"
              :aria-label="$options.i18n.addButtonText"
              @click="toggleResourceLinkForm"
            />
          </div>
        </h3>
      </div>
      <div
        class="linked-issues-card-body bg-gray-light"
        :class="{
          'gl-p-5': isFormVisible,
        }"
      >
        <div v-show="isFormVisible" class="card-body bordered-box gl-bg-white">
          <add-issuable-resource-link-form
            ref="resourceLinkForm"
            :is-submitting="isSubmitting"
            @add-issuable-resource-link-form-cancel="hideResourceLinkForm"
          />
        </div>
      </div>
    </div>
  </div>
</template>
