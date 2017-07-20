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

      <ul>
        <li>
          <a href="#" title="New File">
            <i class="fa fa-file-o"></i>
          </a>
        </li>

        <li>
          <a href="#" title="New Folder">
            <i class="fa fa-folder-o"></i>
          </a>
        </li>
      </ul>
    </td>
  </tr>
</template>
