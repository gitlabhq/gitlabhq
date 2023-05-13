<script>
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-merge-requests-md.svg?url';
import api from '~/api';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'MRWidgetNothingToMerge',
  components: {
    GlButton,
    GlSprintf,
    GlLink,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  methods: {
    onClickNewFile() {
      api.trackRedisHllUserEvent('i_code_review_widget_nothing_merge_click_new_file');
    },
  },
  ciHelpPage: helpPagePath('ci/quick_start/index.html'),
  EMPTY_STATE_SVG_URL,
};
</script>

<template>
  <div class="mr-widget-body mr-widget-empty-state">
    <div class="row">
      <div
        class="col-md-3 col-12 text-center d-flex justify-content-center align-items-center svg-content svg-150 pb-0 pt-0"
      >
        <img
          :alt="s__('mrWidgetNothingToMerge|This merge request contains no changes.')"
          :src="$options.EMPTY_STATE_SVG_URL"
        />
      </div>
      <div class="text col-md-9 col-12">
        <p class="highlight">
          {{ s__('mrWidgetNothingToMerge|This merge request contains no changes.') }}
        </p>
        <p data-testid="nothing-to-merge-body">
          <gl-sprintf
            :message="
              s__(
                'mrWidgetNothingToMerge|Use merge requests to propose changes to your project and discuss them with your team. To make changes, push a commit or edit this merge request to use a different branch. With %{linkStart}CI/CD%{linkEnd}, automatically test your changes before merging.',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="$options.ciHelpPage" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
        <div>
          <gl-button
            v-if="mr.newBlobPath"
            :href="mr.newBlobPath"
            category="primary"
            variant="confirm"
            data-testid="createFileButton"
            @click="onClickNewFile"
          >
            {{ __('Create file') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
