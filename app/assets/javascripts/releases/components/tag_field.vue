<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import TagFieldExisting from './tag_field_existing.vue';
import TagFieldNew from './tag_field_new.vue';

export default {
  components: {
    TagFieldExisting,
    TagFieldNew,
  },
  computed: {
    ...mapState('editNew', ['isExistingRelease']),
  },
};
</script>

<template>
  <tag-field-existing v-if="isExistingRelease" />
  <tag-field-new v-else />
</template>
