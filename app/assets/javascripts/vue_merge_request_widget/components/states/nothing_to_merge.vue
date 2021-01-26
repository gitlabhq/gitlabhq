<script>
/* eslint-disable vue/no-v-html */
import emptyStateSVG from 'icons/_mr_widget_empty_state.svg';
import { GlButton } from '@gitlab/ui';

export default {
  name: 'MRWidgetNothingToMerge',
  components: {
    GlButton,
  },
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
      <div
        class="artwork col-md-5 order-md-last col-12 text-center d-flex justify-content-center align-items-center"
      >
        <span v-html="emptyStateSVG"></span>
      </div>
      <div class="text col-md-7 order-md-first col-12">
        <p class="highlight">
          {{
            s__(
              'mrWidgetNothingToMerge|Merge requests are a place to propose changes you have made to a project and discuss those changes with others.',
            )
          }}
        </p>
        <p>
          {{
            s__(
              'mrWidgetNothingToMerge|Interested parties can even contribute by pushing commits if they want to.',
            )
          }}
        </p>
        <p>
          {{
            s__(
              "mrWidgetNothingToMerge|Currently there are no changes in this merge request's source branch. Please push new commits or use a different branch.",
            )
          }}
        </p>
        <div>
          <gl-button
            v-if="mr.newBlobPath"
            :href="mr.newBlobPath"
            category="secondary"
            variant="success"
          >
            {{ __('Create file') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
