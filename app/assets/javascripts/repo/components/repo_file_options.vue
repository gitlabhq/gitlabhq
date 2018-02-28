<script>
const RepoFileOptions = {
  props: {
    isMini: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectName: {
      type: String,
      required: true,
    },
  },
};

export default RepoFileOptions;
</script>

<template>
  <tr v-if="isMini" class="repo-file-options">
    <td>
      <span class="title">{{projectName}}</span>
    </td>
  </tr>
</template>
