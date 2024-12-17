<script>
import { GlPopover } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

export default {
  i18n: {
    issueTypes: __('Issue types'),
    issue: __('Issue'),
    incident: __('Incident'),
    issueHelpText: __('For general work'),
    incidentHelpText: __('For investigating IT service disruptions or outages'),
  },
  components: {
    HelpIcon,
    GlPopover,
  },
};
</script>

<template>
  <span id="popovercontainer" class="gl-ml-2">
    <help-icon id="issue-type-info" />

    <gl-popover
      target="issue-type-info"
      container="popovercontainer"
      :title="$options.i18n.issueTypes"
      triggers="focus hover"
    >
      <ul class="gl-m-0 gl-list-none gl-p-0">
        <li class="gl-mb-3">
          <div class="gl-font-bold">{{ $options.i18n.issue }}</div>
          <span>{{ $options.i18n.issueHelpText }}</span>
        </li>
        <li>
          <div class="gl-font-bold">{{ $options.i18n.incident }}</div>
          <span>{{ $options.i18n.incidentHelpText }}</span>
        </li>
      </ul>
    </gl-popover>
  </span>
</template>
