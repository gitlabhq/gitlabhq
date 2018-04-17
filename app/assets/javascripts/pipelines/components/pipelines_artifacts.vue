<script>
  import tooltip from '../../vue_shared/directives/tooltip';
  import icon from '../../vue_shared/components/icon.vue';

  export default {
    directives: {
      tooltip,
    },
    components: {
      icon,
    },
    props: {
      artifacts: {
        type: Array,
        required: true,
      },
    },
  };
</script>
<template>
  <div
    class="btn-group"
    role="group"
  >
    <button
      v-tooltip
      class="dropdown-toggle btn btn-secondary build-artifacts js-pipeline-dropdown-download"
      title="Artifacts"
      data-placement="top"
      data-toggle="dropdown"
      aria-label="Artifacts"
    >
      <icon name="download" />
      <i
        class="fa fa-caret-down"
        aria-hidden="true"
      >
      </i>
    </button>
    <ul class="dropdown-menu dropdown-menu-right">
      <li
        v-for="(artifact, i) in artifacts"
        :key="i">
        <a
          rel="nofollow"
          download
          :href="artifact.path"
        >
          Download {{ artifact.name }} artifacts
        </a>
      </li>
    </ul>
  </div>
</template>
