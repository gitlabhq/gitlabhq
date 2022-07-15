<script>
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import {
  LINKED_RESOURCES_HEADER_TEXT,
  LINKED_RESOURCES_HELP_TEXT,
  LINKED_RESOURCES_ADD_BUTTON_TEXT,
} from '../constants';

export default {
  name: 'ResourceLinksBlock',
  components: {
    GlLink,
    GlButton,
    GlIcon,
  },
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
  computed: {
    helpLinkText() {
      return LINKED_RESOURCES_HELP_TEXT;
    },
    badgeLabel() {
      return 0;
    },
    resourceLinkAddButtonText() {
      return LINKED_RESOURCES_ADD_BUTTON_TEXT;
    },
    resourceLinkHeaderText() {
      return LINKED_RESOURCES_HEADER_TEXT;
    },
  },
};
</script>

<template>
  <div id="resource-links" class="gl-mt-5">
    <div class="card card-slim gl-overflow-hidden">
      <div
        :class="{ 'panel-empty-heading border-bottom-0': true }"
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
          <slot name="header-text">{{ resourceLinkHeaderText }}</slot>
          <gl-link
            :href="helpPath"
            target="_blank"
            class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
            data-testid="help-link"
            :aria-label="helpLinkText"
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
              :aria-label="resourceLinkAddButtonText"
            />
          </div>
        </h3>
      </div>
    </div>
  </div>
</template>
