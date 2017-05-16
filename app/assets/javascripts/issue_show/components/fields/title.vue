<script>
  import descriptionTemplate from './template.vue';

  export default {
    props: {
      formState: {
        type: Object,
        required: true,
      },
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
    },
    components: {
      descriptionTemplate,
    },
    computed: {
      hasIssuableTemplates() {
        return this.issuableTemplates.length !== 0;
      },
    },
  };
</script>

<template>
  <fieldset class="row">
    <div
      class="col-sm-4 col-lg-3"
      v-if="hasIssuableTemplates">
      <description-template
        :issuable-templates="issuableTemplates" />
    </div>
    <div
      :class="{
        'col-sm-8 col-lg-9': hasIssuableTemplates,
        'col-xs-12': !hasIssuableTemplates,
      }">
      <label
        class="sr-only"
        for="issue-title">
        Title
      </label>
      <input
        id="issue-title"
        class="form-control"
        type="text"
        placeholder="Issue title"
        aria-label="Issue title"
        v-model="formState.title" />
    </div>
  </fieldset>
</template>
