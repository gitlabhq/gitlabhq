<script>
import { GlPopover, GlFormInputGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    GlPopover,
    GlFormInputGroup,
    ClipboardButton,
  },
  inject: ['pushToCreateProjectCommand', 'workingWithProjectsHelpPath'],
  props: {
    target: {
      type: [Function, HTMLElement],
      required: true,
    },
  },
  i18n: {
    clipboardButtonTitle: __('Copy command'),
    commandInputAriaLabel: __('Push project from command line'),
    helpLinkText: __('What does this command do?'),
    labelText: __('Private projects can be created in your personal namespace with:'),
    popoverTitle: __('Push to create a project'),
  },
};
</script>
<template>
  <gl-popover
    :target="target"
    :title="$options.i18n.popoverTitle"
    triggers="click blur"
    placement="top"
  >
    <p>
      <label for="push-to-create-tip" class="gl-font-weight-normal">
        {{ $options.i18n.labelText }}
      </label>
    </p>
    <p>
      <gl-form-input-group
        id="push-to-create-tip"
        :value="pushToCreateProjectCommand"
        readonly
        select-on-click
        :aria-label="$options.i18n.commandInputAriaLabel"
      >
        <template #append>
          <clipboard-button
            :text="pushToCreateProjectCommand"
            :title="$options.i18n.clipboardButtonTitle"
            tooltip-placement="right"
          />
        </template>
      </gl-form-input-group>
    </p>
    <p>
      <a
        :href="`${workingWithProjectsHelpPath}#push-to-create-a-new-project`"
        class="gl-font-sm"
        target="_blank"
        >{{ $options.i18n.helpLinkText }}</a
      >
    </p>
  </gl-popover>
</template>
