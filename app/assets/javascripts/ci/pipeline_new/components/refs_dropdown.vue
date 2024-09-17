<script>
import { __ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import { formatToShortName } from '../utils/format_refs';

export default {
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
    queryParams: {
      type: Object,
      required: false,
      default: () => ({
        sort: 'updated_desc',
      }),
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
    :project-id="projectId"
    :translations="$options.i18n"
    :use-symbolic-ref-names="true"
    :query-params="queryParams"
    toggle-button-class="!gl-w-auto !gl-mb-0"
    @input="setRefSelected"
  />
</template>
