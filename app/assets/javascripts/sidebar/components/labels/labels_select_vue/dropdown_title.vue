<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_header.vue` instead.
export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  props: {
    labelsSelectInProgress: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['allowLabelEdit', 'labelsFetchInProgress']),
  },
  methods: {
    ...mapActions(['toggleDropdownContents']),
  },
};
</script>

<template>
  <div class="hide-collapsed gl-leading-20 gl-mb-2 gl-text-gray-900 gl-font-bold gl-mb-0">
    {{ __('Labels') }}
    <template v-if="allowLabelEdit">
      <gl-loading-icon v-show="labelsSelectInProgress" size="sm" inline />
      <gl-button
        category="tertiary"
        size="small"
        class="gl-float-right js-sidebar-dropdown-toggle -gl-mr-2"
        @click="toggleDropdownContents"
      >
        {{ __('Edit') }}
      </gl-button>
    </template>
  </div>
</template>
