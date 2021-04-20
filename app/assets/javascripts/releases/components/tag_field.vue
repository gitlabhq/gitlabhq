<script>
import { mapGetters } from 'vuex';
import TagFieldExisting from './tag_field_existing.vue';
import TagFieldNew from './tag_field_new.vue';

export default {
  components: {
    TagFieldExisting,
    TagFieldNew,
  },
  computed: {
    ...mapGetters('editNew', ['isExistingRelease']),
  },
};
</script>

<template>
  <tag-field-existing v-if="isExistingRelease" />
  <tag-field-new v-else />
</template>
