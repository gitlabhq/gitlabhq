<script>
  export default {
    props: {
      formState: {
        type: Object,
        required: true,
      },
    },
  };
</script>

<template>
  <fieldset class="checkbox">
    <label for="issue_confidential">
      <input
        type="checkbox"
        value="1"
        id="issue_confidential"
        v-model="formState.confidential" />
      This issue is confidential and should only be visible to team members with at least Reporter access.
    </label>
  </fieldset>
</template>
