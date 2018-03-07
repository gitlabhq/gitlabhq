<script>
  export default {
    name: 'EnvironmentsEmptyState',
    props: {
      newPath: {
        type: String,
        required: true,
      },
      canCreateEnvironment: {
        type: Boolean,
        required: true,
      },
      helpPath: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="blank-state-row">
    <div class="blank-state-center">
      <h2 class="blank-state-title js-blank-state-title">
        {{ s__("Environments|You don't have any environments right now.") }}
      </h2>
      <p class="blank-state-text">
        {{ s__(`Environments|Environments are places where
code gets deployed, such as staging or production.`) }}
        <br />
        <a :href="helpPath">
          {{ s__("Environments|Read more about environments") }}
        </a>
      </p>

      <a
        v-if="canCreateEnvironment"
        :href="newPath"
        class="btn btn-create js-new-environment-button"
      >
        {{ s__("Environments|New environment") }}
      </a>
    </div>
  </div>
</template>
