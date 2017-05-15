<script>
  import descriptionTemplate from './template.vue';

  export default {
    props: {
      store: {
        type: Object,
        required: true,
      },
      issuableTemplates: {
        type: Array,
        required: false,
        default: () => [],
      },
    },
    data() {
      return {
        state: this.store.formState,
      };
    },
    components: {
      descriptionTemplate,
    },
  };
</script>

<template>
  <fieldset class="row">
    <div class="col-sm-4 col-lg-3">
      <description-template
        :issuable-templates="issuableTemplates" />
    </div>
    <div class="col-sm-8 col-lg-9">
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
        v-model="state.title" />
    </div>
  </fieldset>
</template>
