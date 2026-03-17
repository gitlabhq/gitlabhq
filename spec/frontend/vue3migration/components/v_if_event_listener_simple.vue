<script>
import SimpleButton from './simple_button.vue';

export default {
  name: 'VIfEventListenerSimple',
  components: {
    SimpleButton,
  },
  data() {
    return {
      isEditing: false,
      lastAction: null,
    };
  },
  methods: {
    startEdit() {
      this.lastAction = 'edit';
      this.isEditing = true;
    },
    save() {
      this.lastAction = 'save';
      this.isEditing = false;
    },
  },
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <simple-button v-if="isEditing" data-testid="save-btn" @click="save"> Save </simple-button>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <simple-button v-else data-testid="edit-btn" @click="startEdit"> Edit </simple-button>
    <span data-testid="last-action">{{ lastAction }}</span>
  </div>
</template>
