<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  i18n: {
    learnTasksButtonText: s__('WorkItem|Learn about tasks'),
    workItemsText: s__('WorkItem|work items'),
    tasksInformationTitle: s__('WorkItem|Introducing tasks'),
    tasksInformationBody: s__(
      'WorkItem|A task provides the ability to break down your work into smaller pieces tied to an issue. Tasks are the first items using our new %{workItemsLink} objects. Additional work item types will be coming soon.',
    ),
  },
  helpPageLinks: {
    tasksDocLinkPath: helpPagePath('user/tasks'),
    workItemsLinkPath: helpPagePath(`development/work_items`),
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
      :primary-button-link="$options.helpPageLinks.tasksDocLinkPath"
      :primary-button-text="$options.i18n.learnTasksButtonText"
      data-testid="work-item-information"
      class="gl-mt-3"
      @dismiss="$emit('work-item-banner-dismissed')"
    >
      <gl-sprintf :message="$options.i18n.tasksInformationBody">
        <template #workItemsLink>
          <gl-link :href="$options.helpPageLinks.workItemsLinkPath">{{
            $options.i18n.workItemsText
          }}</gl-link>
        </template>
        ></gl-sprintf
      >
    </gl-alert>
  </section>
</template>
