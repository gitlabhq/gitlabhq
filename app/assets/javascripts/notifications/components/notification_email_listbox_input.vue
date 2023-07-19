<script>
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';

export default {
  components: {
    ListboxInput,
  },
  inject: ['label', 'name', 'emails', 'emptyValueText', 'value', 'disabled', 'placement'],
  data() {
    return {
      selected: this.value,
    };
  },
  computed: {
    options() {
      return [
        {
          value: '',
          text: this.emptyValueText,
        },
        ...this.emails.map((email) => ({
          text: email,
          value: email,
        })),
      ];
    },
  },
  methods: {
    async onSelect() {
      await this.$nextTick();
      this.$el.closest('form').submit();
    },
  },
};
</script>

<template>
  <listbox-input
    v-model="selected"
    :label="label"
    :name="name"
    :items="options"
    :disabled="disabled"
    :placement="placement"
    fluid-width
    @select="onSelect"
  />
</template>
