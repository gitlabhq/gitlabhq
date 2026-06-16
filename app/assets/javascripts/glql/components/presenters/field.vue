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
    variant: {
      required: false,
      type: String,
      default: 'default',
    },
  },
  computed: {
    data() {
      return dataForField(this.item, this.fieldKey);
    },
    presenter() {
      return presenterFor(this.item, this.fieldKey, this.variant);
    },
  },
};
</script>
<template>
  <component :is="presenter" :item="item" :data="data" />
</template>
