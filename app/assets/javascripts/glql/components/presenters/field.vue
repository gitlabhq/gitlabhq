<script>
import { dataForField, presenterFor } from './presenter_registry';

export default {
  name: 'FieldPresenter',
  props: {
    item: {
      required: true,
      type: Object,
    },
    fieldKey: {
      required: false,
      type: String,
      default: '',
    },
    presenterKey: {
      required: false,
      type: String,
      default: '',
    },
    variant: {
      required: false,
      type: String,
      default: 'default',
    },
    // The field spec's parameter map (e.g. `{ granularity: 'monthly' }`).
    parameters: {
      required: false,
      type: Object,
      default: undefined,
    },
  },
  computed: {
    data() {
      return dataForField(this.item, this.fieldKey, this.presenterKey);
    },
    presenter() {
      return presenterFor(this.item, this.fieldKey, {
        variant: this.variant,
        presenterKey: this.presenterKey,
        parameters: this.parameters,
      });
    },
    // Bind only the props the presenter declares. Under Vue 3 a fallthrough
    // attr on a component root overrides that component's own prop, so an
    // undeclared `item` replaced the status badge's `:item="data"`.
    presenterProps() {
      const declared = this.presenter?.props ?? {};
      const declares = (key) =>
        Array.isArray(declared) ? declared.includes(key) : key in declared;
      const available = { item: this.item, data: this.data, parameters: this.parameters };

      return Object.fromEntries(Object.entries(available).filter(([key]) => declares(key)));
    },
  },
};
</script>
<template>
  <component :is="presenter" v-bind="presenterProps" />
</template>
