<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlDropdownDivider,
} from '@gitlab/ui';
import { getParameterByName, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';

const i18n = {
  learnMore: __('Learn more'),
  blamePreferences: s__('Blame|Blame preferences'),
  ignoreSpecificRevs: s__('Blame|Ignore specific revisions'),
  learnToIgnore: s__('Blame|Learn to ignore specific revisions'),
};

export default {
  i18n,
  components: { GlDisclosureDropdown, GlDisclosureDropdownItem, GlFormCheckbox, GlDropdownDivider },
  props: {
    hasRevsFile: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isIgnoring: getParameterByName('ignore_revs') || false,
      isLoading: false,
    };
  },
  methods: {
    toggleIgnoreRevs() {
      this.isLoading = true;
      visitUrl(setUrlParams({ ignore_revs: this.isIgnoring }));
    },
    visitDocs() {
      // TODO: link to docs page once docs is ready
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :toggle-text="$options.i18n.blamePreferences"
    :loading="isLoading"
    class="gl-m-3"
  >
    <template v-if="!hasRevsFile">
      <gl-disclosure-dropdown-item>{{ $options.i18n.learnToIgnore }}</gl-disclosure-dropdown-item>
    </template>

    <template v-else>
      <gl-form-checkbox
        v-model="isIgnoring"
        class="!gl-mx-4 gl-pb-2 gl-pt-4"
        @input="toggleIgnoreRevs"
        >{{ $options.i18n.ignoreSpecificRevs }}</gl-form-checkbox
      >

      <gl-dropdown-divider />
      <gl-disclosure-dropdown-item class="gl-p-4">{{
        $options.i18n.learnMore
      }}</gl-disclosure-dropdown-item>
    </template>
  </gl-disclosure-dropdown>
</template>
