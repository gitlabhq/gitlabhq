<script>
  import icon from '~/vue_shared/components/icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import '~/lib/utils/datetime_utility';

  export default {
    components: {
      icon,
    },
    directives: {
      tooltip,
    },
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    computed: {
      lockTooltip() {
        return `Locked by ${this.file.file_lock.user.name}`;
      },
    },
  };
</script>

<template>
  <span
    v-if="file.file_lock"
    v-tooltip
    :title="lockTooltip"
    data-container="body"
  >
    <icon
      name="lock"
      css-classes="file-status-icon"
    />
  </span>
</template>
