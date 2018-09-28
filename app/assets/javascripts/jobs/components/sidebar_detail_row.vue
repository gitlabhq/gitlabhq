<script>
  export default {
    name: 'SidebarDetailRow',
    props: {
      title: {
        type: String,
        required: false,
        default: '',
      },
      value: {
        type: String,
        required: true,
      },
      helpUrl: {
        type: String,
        required: false,
        default: '',
      },
    },
    computed: {
      hasTitle() {
        return this.title.length > 0;
      },
      hasHelpURL() {
        return this.helpUrl.length > 0;
      },
    },
  };
</script>
<template>
  <p class="build-detail-row">
    <span
      v-if="hasTitle"
      class="build-light-text"
    >
      {{ title }}:
    </span>
    {{ value }}

    <span
      v-if="hasHelpURL"
      class="help-button float-right"
    >
      <a
        :href="helpUrl"
        target="_blank"
        rel="noopener noreferrer nofollow"
      >
        <i
          class="fa fa-question-circle"
          aria-hidden="true"
        ></i>
      </a>
    </span>
  </p>
</template>
