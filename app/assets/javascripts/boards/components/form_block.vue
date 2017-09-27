<template>
  <div class="list-item">
    <div class="media">
      <label class="label-light media-body">{{ title }}</label>
      <a
        v-if="canEdit"
        class="edit-link"
        href="#"
        @click.prevent="toggleEditing"
      >
        Edit
      </a>
    </div>
    <slot></slot>
    <div>
      <slot name="currentValue">
        {{ defaultText }}
      </slot>
    </div>
  </div>
</template>

<script>
import eventHub from '../eventhub';

export default {
  props: {
    defaultText: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    fieldName: {
      type: String,
      required: false,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      editing: false,
    };
  },
  methods: {
    toggleEditing() {
      eventHub.$emit('toggle');
    },
  },
};
</script>
