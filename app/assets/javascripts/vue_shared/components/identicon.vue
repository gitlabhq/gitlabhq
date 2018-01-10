<script>
export default {
  props: {
    entityId: {
      type: Number,
      required: true,
    },
    entityName: {
      type: String,
      required: true,
    },
    sizeClass: {
      type: String,
      required: false,
      default: 's40',
    },
  },
  computed: {
    /**
     * This method is based on app/helpers/application_helper.rb#project_identicon
     */
    identiconStyles() {
      const allowedColors = [
        '#FFEBEE',
        '#F3E5F5',
        '#E8EAF6',
        '#E3F2FD',
        '#E0F2F1',
        '#FBE9E7',
        '#EEEEEE',
      ];

      const backgroundColor = allowedColors[this.entityId % 7];

      return `background-color: ${backgroundColor}; color: #555;`;
    },
    identiconTitle() {
      return this.entityName.charAt(0).toUpperCase();
    },
  },
};
</script>

<template>
  <div
    class="avatar identicon"
    :class="sizeClass"
    :style="identiconStyles">
    {{ identiconTitle }}
  </div>
</template>
