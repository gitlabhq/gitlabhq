<template>
  <div class="board-inner-container">
    <div class="media">
      <label class="media-body">{{ title }}</label>
      <a
        v-if="canEdit"
        href="#"
        @click.prevent="toggleEditing"
      >
        Edit
      </a>
    </div>
    <div class="droplab-dropdown">
      <div v-if="editing">
        <input
          v-if="fieldName"
          :name="fieldName"
        >
        <slot></slot>
      </div>
      <div v-else>
        {{ defaultText }}
      </div>
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