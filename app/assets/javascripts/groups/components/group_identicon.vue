<script>
export default {
  props: {
    id: {
      required: true,
    },
    name: {
      type: String,
      required: true,
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

      const backgroundColor = allowedColors[this.id % 7];

      return `background-color: ${backgroundColor}; color: #555;`;
    },
    identiconTitle() {
      return this.name.charAt(0).toUpperCase();
    }
  }
};
</script>

<template>
  <div
    class="avatar s40 identicon"
    :style="identiconStyles">
    {{identiconTitle}}
  </div>
</template>
