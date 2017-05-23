<script>
<<<<<<< HEAD
<<<<<<< HEAD
  import descriptionTemplate from './template.vue';
=======
  import updateMixin from '../../mixins/update';
>>>>>>> 29fd130... enable meta+enter shortcut to quick submit

  export default {
    mixins: [updateMixin],
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
=======
  export default {
    props: {
      store: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        state: this.store.formState,
      };
>>>>>>> b1affe0... Issue inline edit title field
    },
  };
</script>

<template>
<<<<<<< HEAD
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
=======
  <fieldset>
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
<<<<<<< HEAD
      v-model="state.title" />
>>>>>>> b1affe0... Issue inline edit title field
=======
      v-model="formState.title"
      @keydown.meta.enter="updateIssuable" />
>>>>>>> 29fd130... enable meta+enter shortcut to quick submit
  </fieldset>
</template>
