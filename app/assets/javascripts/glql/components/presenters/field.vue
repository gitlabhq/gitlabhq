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
    // The field spec's parameter map (e.g. `{ granularity: 'monthly' }`). Left
    // undefined for plain fields so it doesn't fall through as a DOM attribute.
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
  },
};
</script>
<template>
  <component :is="presenter" :item="item" :data="data" :parameters="parameters" />
</template>
