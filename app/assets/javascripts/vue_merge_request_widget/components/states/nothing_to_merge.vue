<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-merge-requests-md.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'MRWidgetNothingToMerge',
  components: {
    GlSprintf,
    GlLink,
  },
  ciHelpPage: helpPagePath('ci/quick_start/index.html'),
  EMPTY_STATE_SVG_URL,
};
</script>

<template>
  <div class="mr-widget-body mr-widget-empty-state">
    <div class="row">
      <div
        class="col-md-3 col-12 text-center d-flex justify-content-center align-items-center svg-content svg-130 pb-0 pt-0"
      >
        <img :src="$options.EMPTY_STATE_SVG_URL" :alt="''" />
      </div>
      <div class="text col-md-9 col-12">
        <p class="highlight mt-3">
          {{ s__('mrWidgetNothingToMerge|Merge request contains no changes') }}
        </p>
        <p data-testid="nothing-to-merge-body">
          <gl-sprintf
            :message="
              s__(
                'mrWidgetNothingToMerge|Use merge requests to propose changes to your project and discuss them with your team. To make changes, use the %{boldStart}Code%{boldEnd} dropdown list above, then test them with %{linkStart}CI/CD%{linkEnd} before merging.',
              )
            "
          >
            <template #bold="{ content }">
              <b>{{ content }}</b>
            </template>
            <template #link="{ content }">
              <gl-link :href="$options.ciHelpPage" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>
    </div>
  </div>
</template>
