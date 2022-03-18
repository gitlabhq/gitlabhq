<script>
import ForkForm from './fork_form.vue';

export default {
  components: {
    ForkForm,
  },
  props: {
    forkIllustration: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="row gl-mt-5">
    <div class="col-lg-3">
      <img :src="forkIllustration" />
      <h4 class="">{{ s__('ForkProject|Fork project') }}</h4>
      <p>
        {{ s__('ForkProject|A fork is a copy of a project.') }}
        <br />
        {{
          s__(
            'ForkProject|Forking a repository allows you to make changes without affecting the original project.',
          )
        }}
      </p>
    </div>
    <div class="col-lg-9">
      <fork-form />
    </div>
  </div>
</template>
