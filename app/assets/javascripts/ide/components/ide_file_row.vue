<script>
/**
 * This component is an iterative step towards refactoring and simplifying `vue_shared/components/file_row.vue`
 * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23720
 */
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowExtra from './file_row_extra.vue';

export default {
  name: 'IdeFileRow',
  components: {
    FileRow,
    FileRowExtra,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      dropdownOpen: false,
    };
  },
  computed: {
    ...mapGetters(['getUrlForPath']),
  },
  methods: {
    toggleDropdown(val) {
      this.dropdownOpen = val;
    },
  },
};
</script>

<template>
  <file-row
    :file="file"
    :file-url="getUrlForPath(file.path)"
    v-bind="$attrs"
    @mouseleave="toggleDropdown(false)"
    v-on="$listeners"
  >
    <file-row-extra :file="file" :dropdown-open="dropdownOpen" @toggle="toggleDropdown($event)" />
  </file-row>
</template>
