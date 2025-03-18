<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlDropdownDivider,
} from '@gitlab/ui';
import { getParameterByName, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

const i18n = {
  blamePreferences: s__('Blame|Blame preferences'),
  ignoreSpecificRevs: s__('Blame|Ignore specific revisions'),
  learnToIgnore: s__('Blame|Learn to ignore specific revisions'),
};

export default {
  i18n,
  docsLink: helpPagePath('user/project/repository/files/git_blame.md', {
    anchor: 'ignore-specific-revisions',
  }),
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
      visitUrl(this.$options.docsLink);
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
      <div class="gl-m-3">
        <gl-disclosure-dropdown-item @action="visitDocs">{{
          $options.i18n.learnToIgnore
        }}</gl-disclosure-dropdown-item>
      </div>
    </template>

    <template v-else>
      <gl-form-checkbox
        v-model="isIgnoring"
        class="!gl-mx-4 gl-pb-2 gl-pt-4"
        @input="toggleIgnoreRevs"
        >{{ $options.i18n.ignoreSpecificRevs }}</gl-form-checkbox
      >

      <gl-dropdown-divider />
      <gl-disclosure-dropdown-item class="gl-p-4" @action="visitDocs">{{
        $options.i18n.learnToIgnore
      }}</gl-disclosure-dropdown-item>
    </template>
  </gl-disclosure-dropdown>
</template>
