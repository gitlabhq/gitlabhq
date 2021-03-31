<script>
import { GlIcon, GlPopover } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    issueTypes: __('Issue types'),
    issue: __('Issue'),
    incident: __('Incident'),
    issueHelpText: __('For general work'),
    incidentHelpText: __('For investigating IT service disruptions or outages'),
  },
  components: {
    GlIcon,
    GlPopover,
  },
};
</script>

<template>
  <span id="popovercontainer">
    <gl-icon id="issuable-type-info" name="question-o" class="gl-ml-5 gl-text-gray-500" />
    <gl-popover
      target="issuable-type-info"
      container="popovercontainer"
      :title="$options.i18n.issueTypes"
      triggers="focus hover"
    >
      <ul class="gl-list-style-none gl-p-0 gl-m-0">
        <li class="gl-mb-3">
          <div class="gl-font-weight-bold">{{ $options.i18n.issue }}</div>
          <span>{{ $options.i18n.issueHelpText }}</span>
        </li>
        <li>
          <div class="gl-font-weight-bold">{{ $options.i18n.incident }}</div>
          <span>{{ $options.i18n.incidentHelpText }}</span>
        </li>
      </ul>
    </gl-popover>
  </span>
</template>
