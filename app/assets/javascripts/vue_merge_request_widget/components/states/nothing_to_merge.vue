<script>
import emptyStateSVG from 'icons/_mr_widget_empty_state.svg';

export default {
  name: 'MRWidgetNothingToMerge',
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { emptyStateSVG };
  },
};
</script>

<template>
  <div class="mr-widget-body mr-widget-empty-state">
    <div class="row">
      <div class="artwork col-sm-5 col-sm-push-7 col-xs-12 text-center">
        <span v-html="emptyStateSVG"></span>
      </div>
      <div class="text col-sm-7 col-sm-pull-5 col-xs-12">
        <span>
          Merge requests are a place to propose changes you have made to a project
          and discuss those changes with others.
        </span>
        <p>
          Interested parties can even contribute by pushing commits if they want to.
        </p>
        <p>
          Currently there are no changes in this merge request's source branch.
          Please push new commits or use a different branch.
        </p>
        <div>
          <a
            v-if="mr.newBlobPath"
            :href="mr.newBlobPath"
            class="btn btn-inverted btn-save">
            Create file
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
