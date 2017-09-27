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
    <div
      v-if="editing"
      class="dropdown open"
    >
      <input
        v-if="fieldName"
        :name="fieldName"
      >
      <slot></slot>
    </div>
    <div :class="{ invisible: editing }">
      <slot name="currentValue">
        {{ defaultText }}
      </slot>
    </div>
  </div>
</template>

<script>
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
      }
    },
    data() {
      return {
        editing: false,
      };
    },
    methods: {
      toggleEditing() {
        this.editing = !this.editing;
      },
    },
  };
</script>