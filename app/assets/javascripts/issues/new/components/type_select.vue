<script>
import { GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_INCIDENT } from '~/issues/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import { __ } from '~/locale';

export default {
  i18n: {
    selectType: __('Select type'),
    issuableType: {
      [TYPE_ISSUE]: __('Issue'),
      [TYPE_INCIDENT]: __('Incident'),
    },
  },
  components: {
    GlCollapsibleListbox,
    GlIcon,
  },
  mixins: [Tracking.mixin()],
  props: {
    selectedType: {
      required: false,
      default: '',
      type: String,
    },
    isIssueAllowed: {
      required: false,
      default: false,
      type: Boolean,
    },
    isIncidentAllowed: {
      required: false,
      default: false,
      type: Boolean,
    },
    issuePath: {
      required: false,
      default: '',
      type: String,
    },
    incidentPath: {
      required: false,
      default: '',
      type: String,
    },
  },
  data() {
    return {
      selected: this.selectedType,
    };
  },
  computed: {
    toggleText() {
      return this.selectedType
        ? this.$options.i18n.issuableType[this.selectedType]
        : this.$options.i18n.selectType;
    },
    dropdownItems() {
      const issueItem = this.isIssueAllowed
        ? {
            value: TYPE_ISSUE,
            text: __('Issue'),
            icon: 'issue-type-issue',
            href: this.issuePath,
          }
        : null;
      const incidentItem = this.isIncidentAllowed
        ? {
            value: TYPE_INCIDENT,
            text: __('Incident'),
            icon: 'issue-type-incident',
            href: this.incidentPath,
            tracking: {
              action: 'select_issue_type_incident',
              label: 'select_issue_type_incident_dropdown_option',
            },
          }
        : null;

      return [issueItem, incidentItem].filter(Boolean);
    },
  },
  methods: {
    selectType(type) {
      const selectedItem = this.dropdownItems.find((item) => item.value === type);
      if (selectedItem.tracking) {
        const { action, label } = selectedItem.tracking;
        this.track(action, { label });
      }

      visitUrl(selectedItem.href);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selected"
    :header-text="$options.i18n.selectType"
    :toggle-text="toggleText"
    :items="dropdownItems"
    block
    class="js-issuable-type-filter-dropdown-wrap"
    @select="selectType"
  >
    <template #list-item="{ item }">
      <gl-icon :name="item.icon" :size="16" />
      {{ item.text }}
    </template>
  </gl-collapsible-listbox>
</template>
