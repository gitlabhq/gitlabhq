<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  i18n: {
    learnTasksLinkText: s__('WorkItem|Learn about tasks.'),
    tasksInformationTitle: s__('WorkItem|Introducing tasks'),
    tasksInformationBody: s__(
      'WorkItem|Use tasks to break down your work in an issue into smaller pieces. %{learnMoreLink}',
    ),
  },
  helpPageLinks: {
    tasksDocLinkPath: helpPagePath('user/tasks'),
  },
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  props: {
    showInfoBanner: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  emits: ['work-item-banner-dismissed'],
};
</script>

<template>
  <section class="gl-display-block gl-mb-2">
    <gl-alert
      v-if="showInfoBanner"
      variant="tip"
      :title="$options.i18n.tasksInformationTitle"
      data-testid="work-item-information"
      class="gl-mt-3"
      @dismiss="$emit('work-item-banner-dismissed')"
    >
      <gl-sprintf :message="$options.i18n.tasksInformationBody">
        <template #learnMoreLink>
          <gl-link :href="$options.helpPageLinks.tasksDocLinkPath">{{
            $options.i18n.learnTasksLinkText
          }}</gl-link>
        </template>
        ></gl-sprintf
      >
    </gl-alert>
  </section>
</template>
