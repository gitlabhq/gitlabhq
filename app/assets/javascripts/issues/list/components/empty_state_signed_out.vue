<script>
import { GlEmptyState, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { i18n } from '../constants';

export default {
  i18n,
  issuesHelpPagePath: helpPagePath('user/project/issues/index'),
  components: {
    GlEmptyState,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['emptyStateSvgPath', 'signInPath'],
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.noIssuesTitle"
    :svg-path="emptyStateSvgPath"
    :primary-button-text="$options.i18n.noIssuesSignedOutButtonText"
    :primary-button-link="signInPath"
  >
    <template #description>
      <gl-link :href="$options.issuesHelpPagePath">
        {{ $options.i18n.noIssuesDescription }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
