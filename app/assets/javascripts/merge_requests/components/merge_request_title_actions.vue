<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { sanitize } from '~/lib/dompurify';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { keysFor, ISSUABLE_EDIT_DESCRIPTION } from '~/behaviors/shortcuts/keybindings';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import PanelActionsPortal from '~/vue_shared/components/panel_actions_portal.vue';
import CodeDropdown from '~/merge_requests/components/code_dropdown.vue';
import MrMoreDropdown from '~/vue_shared/components/mr_more_dropdown.vue';
import TodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';

export default {
  name: 'MergeRequestTitleActions',
  TYPE_MERGE_REQUEST,
  components: {
    GlButton,
    PanelActionsPortal,
    CodeDropdown,
    MrMoreDropdown,
    TodoWidget,
    SubscriptionsWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    id: {
      type: Number,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSignedIn: {
      type: Boolean,
      required: false,
      default: false,
    },
    editPath: {
      type: String,
      required: false,
      default: '',
    },
    codeDropdownProps: {
      type: Object,
      required: false,
      default: null,
    },
    moreDropdownProps: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    issuableGraphqlId() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id);
    },
    editShortcutKey() {
      return keyboardShortcutsDisabled() ? null : keysFor(ISSUABLE_EDIT_DESCRIPTION)[0];
    },
    editTooltip() {
      const description = this.$options.i18n.editDescription;

      return this.editShortcutKey
        ? sanitize(
            `${description} <kbd class="flat gl-ml-1" aria-hidden=true>${this.editShortcutKey}</kbd>`,
          )
        : description;
    },
  },
  i18n: {
    edit: __('Edit'),
    editDescription: __('Edit merge request'),
  },
};
</script>

<template>
  <panel-actions-portal>
    <code-dropdown v-if="codeDropdownProps" v-bind="codeDropdownProps" />
    <gl-button
      v-if="canUpdate"
      v-gl-tooltip.bottom.html
      :href="editPath"
      :title="editTooltip"
      :aria-label="$options.i18n.editDescription"
      :aria-keyshortcuts="editShortcutKey"
      category="tertiary"
      size="small"
      class="js-issuable-edit gl-shrink-0"
      data-testid="edit-title-button"
    >
      {{ $options.i18n.edit }}
    </gl-button>
    <template v-if="isSignedIn">
      <todo-widget
        :issuable-id="issuableGraphqlId"
        :issuable-iid="iid"
        :full-path="projectPath"
        :issuable-type="$options.TYPE_MERGE_REQUEST"
      />
      <subscriptions-widget
        :iid="iid"
        :full-path="projectPath"
        :issuable-type="$options.TYPE_MERGE_REQUEST"
      />
      <mr-more-dropdown v-bind="moreDropdownProps" />
    </template>
  </panel-actions-portal>
</template>
