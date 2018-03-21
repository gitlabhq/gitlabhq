<script>
  import { mapGetters } from 'vuex';
  import icon from '~/vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    computed: {
      ...mapGetters([
        'addedFiles',
        'modifiedFiles',
      ]),
    },
  };
</script>

<template>
  <div
    class="multi-file-commit-list-collapsed text-center"
  >
    <icon
      name="file-addition"
      :size="18"
      css-classes="multi-file-addition append-bottom-10"
    />
    {{ addedFiles.length }}
    <icon
      name="file-modified"
      :size="18"
      css-classes="multi-file-modified prepend-top-10 append-bottom-10"
    />
    {{ modifiedFiles.length }}
  </div>
</template>
