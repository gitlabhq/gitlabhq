<script>
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  components: {
    CrudComponent,
  },
};
</script>

<template>
  <crud-component :title="s__('ContainerRegistry|Protected container tags')">
    <template #default>
      <p class="gl-pb-0 gl-text-subtle" data-testid="description">
        {{
          s__(
            'ContainerRegistry|When a container tag is protected, only certain user roles can update and delete the protected tag, which helps to prevent tampering with the tag. A maximum of 5 protection rules can be added per project.',
          )
        }}
      </p>
    </template>
  </crud-component>
</template>
