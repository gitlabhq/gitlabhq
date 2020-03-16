<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

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
  <div class="title hide-collapsed append-bottom-10">
    {{ __('Labels') }}
    <template v-if="allowLabelEdit">
      <gl-loading-icon v-show="labelsSelectInProgress" inline />
      <gl-button
        variant="link"
        class="pull-right js-sidebar-dropdown-toggle"
        data-qa-selector="labels_edit_button"
        @click="toggleDropdownContents"
        >{{ __('Edit') }}</gl-button
      >
    </template>
  </div>
</template>
