<script>
export default {
  name: 'EnvironmentsEmptyState',
  props: {
    helpPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="empty-state">
    <div class="text-content">
      <h4 class="js-blank-state-title">
        {{ s__("Environments|You don't have any environments right now") }}
      </h4>
      <p>
        {{
          s__(`Environments|Environments are places where
        code gets deployed, such as staging or production.`)
        }}
        <a :href="helpPath"> {{ s__('Environments|More information') }} </a>
      </p>
    </div>
  </div>
</template>
