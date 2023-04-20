<script>
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { BRANCH_REF_TYPE, REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import { formatToShortName } from '../utils/format_refs';

export default {
  BRANCH_REF_TYPE,
  ENABLED_TYPE_REFS: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
  i18n: {
    /**
     * In order to hide ListBox header
     * we need to explicitly provide
     * empty string for translations
     */
    dropdownHeader: '',
    searchPlaceholder: __('Search refs'),
  },
  components: {
    RefSelector,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    value: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    refShortName() {
      return this.value.shortName;
    },
  },
  methods: {
    setRefSelected(fullName) {
      this.$emit('input', {
        shortName: formatToShortName(fullName),
        fullName,
      });
    },
  },
};
</script>
<template>
  <ref-selector
    :value="refShortName"
    :enabled-ref-types="$options.ENABLED_TYPE_REFS"
    :ref-type="$options.BRANCH_REF_TYPE"
    :project-id="projectId"
    :translations="$options.i18n"
    :use-symbolic-ref-names="true"
    toggle-button-class="gl-w-auto! gl-mb-0!"
    @input="setRefSelected"
  />
</template>
