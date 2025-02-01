<script>
import { GlFormGroup, GlLink, GlFormInputGroup } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    GlFormGroup,
    GlLink,
    GlFormInputGroup,
    ClipboardButton,
  },
  directives: {
    SafeHtml,
  },
  inject: ['projectHelpPath', 'pushToCreateProjectCommand'],
};
</script>

<template>
  <div>
    <div class="gl-mb-6 gl-flex gl-items-center gl-gap-4">
      <div class="gl-border-t gl-w-full"></div>
      <div class="gl-text-primary">{{ __('or') }}</div>
      <div class="gl-border-t gl-w-full"></div>
    </div>

    <gl-form-group
      :label="s__('ProjectNew|You can also create a project from the command line')"
      data-testid="new-project-with-command"
    >
      <template #label-description>
        <gl-link :href="`${projectHelpPath}#create-a-new-project-with-git-push`" target="_blank">
          {{ s__('ProjectNew|What does this command do?') }}
        </gl-link>
      </template>
      <gl-form-input-group
        :value="pushToCreateProjectCommand"
        readonly
        select-on-click
        :aria-label="s__('ProjectNew|Push project from command line')"
      >
        <template #append>
          <clipboard-button
            :text="pushToCreateProjectCommand"
            :title="__('Copy command')"
            tooltip-placement="right"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
  </div>
</template>
