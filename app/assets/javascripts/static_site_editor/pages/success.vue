<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

import savedContentMetaQuery from '../graphql/queries/saved_content_meta.query.graphql';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import { HOME_ROUTE } from '../router/constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  props: {
    mergeRequestsIllustrationPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    savedContentMeta: {
      query: savedContentMetaQuery,
    },
    appData: {
      query: appDataQuery,
    },
  },
  computed: {
    updatedFileDescription() {
      const { sourcePath } = this.appData;

      return sprintf(s__('Update %{sourcePath} file'), { sourcePath });
    },
  },
  created() {
    if (!this.savedContentMeta) {
      this.$router.push(HOME_ROUTE);
    }
  },
  title: s__('StaticSiteEditor|Your merge request has been created'),
  primaryButtonText: __('View merge request'),
  returnToSiteBtnText: s__('StaticSiteEditor|Return to site'),
  mergeRequestInstructionsHeading: s__(
    'StaticSiteEditor|To see your changes live you will need to do the following things:',
  ),
  addTitleInstruction: s__('StaticSiteEditor|1. Add a clear title to describe the change.'),
  addDescriptionInstruction: s__(
    'StaticSiteEditor|2. Add a description to explain why the change is being made.',
  ),
  assignMergeRequestInstruction: s__(
    'StaticSiteEditor|3. Assign a person to review and accept the merge request.',
  ),
};
</script>
<template>
  <div
    v-if="savedContentMeta"
    class="container gl-flex-grow-1 gl-display-flex gl-flex-direction-column"
  >
    <div class="gl-fixed gl-left-0 gl-right-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100">
      <div class="container gl-py-4">
        <gl-button
          v-if="appData.returnUrl"
          ref="returnToSiteButton"
          class="gl-mr-5"
          :href="appData.returnUrl"
          >{{ $options.returnToSiteBtnText }}</gl-button
        >
        <strong>
          {{ updatedFileDescription }}
        </strong>
      </div>
    </div>
    <gl-empty-state
      class="gl-my-9"
      :primary-button-text="$options.primaryButtonText"
      :title="$options.title"
      :primary-button-link="savedContentMeta.mergeRequest.url"
      :svg-path="mergeRequestsIllustrationPath"
    >
      <template #description>
        <p>{{ $options.mergeRequestInstructionsHeading }}</p>
        <p>{{ $options.addTitleInstruction }}</p>
        <p>{{ $options.addDescriptionInstruction }}</p>
        <p>{{ $options.assignMergeRequestInstruction }}</p>
      </template>
    </gl-empty-state>
  </div>
</template>
