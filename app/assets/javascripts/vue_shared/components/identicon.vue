<script>
import { getIdenticonBackgroundClass, getIdenticonTitle } from '~/helpers/avatar_helper';

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
    identiconBackgroundClass() {
      return getIdenticonBackgroundClass(this.entityId);
    },
    identiconTitle() {
      return getIdenticonTitle(this.entityName);
    },
  },
};
</script>

<template>
  <div
    :class="[sizeClass, identiconBackgroundClass]"
    class="avatar identicon">
    {{ identiconTitle }}
  </div>
</template>
