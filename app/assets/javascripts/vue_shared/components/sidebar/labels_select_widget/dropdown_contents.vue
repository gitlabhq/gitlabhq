<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';

import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';

export default {
  components: {
    DropdownContentsLabelsView,
    DropdownContentsCreateView,
    GlButton,
  },
  props: {
    renderOnTop: {
      type: Boolean,
      required: false,
      default: false,
    },
    labelsCreateTitle: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['showDropdownContentsCreateView', 'labelsListTitle']),
    ...mapGetters(['isDropdownVariantSidebar', 'isDropdownVariantEmbedded']),
    dropdownContentsView() {
      if (this.showDropdownContentsCreateView) {
        return 'dropdown-contents-create-view';
      }
      return 'dropdown-contents-labels-view';
    },
    directionStyle() {
      const bottom = this.isDropdownVariantSidebar ? '3rem' : '2rem';
      return this.renderOnTop ? { bottom } : {};
    },
    dropdownTitle() {
      return this.showDropdownContentsCreateView ? this.labelsCreateTitle : this.labelsListTitle;
    },
  },
  methods: {
    ...mapActions(['toggleDropdownContentsCreateView', 'toggleDropdownContents']),
  },
};
</script>

<template>
  <div
    class="labels-select-dropdown-contents gl-w-full gl-my-2 gl-py-3 gl-rounded-base gl-absolute"
    data-qa-selector="labels_dropdown_content"
    :style="directionStyle"
  >
    <div
      v-if="isDropdownVariantSidebar || isDropdownVariantEmbedded"
      class="dropdown-title gl-display-flex gl-align-items-center gl-pt-0 gl-pb-3!"
      data-testid="dropdown-title"
    >
      <gl-button
        v-if="showDropdownContentsCreateView"
        :aria-label="__('Go back')"
        variant="link"
        size="small"
        class="js-btn-back dropdown-header-button p-0"
        icon="arrow-left"
        @click="toggleDropdownContentsCreateView"
      />
      <span class="flex-grow-1">{{ dropdownTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button gl-p-0!"
        icon="close"
        @click="toggleDropdownContents"
      />
    </div>
    <component :is="dropdownContentsView" @hideCreateView="toggleDropdownContentsCreateView" />
  </div>
</template>
