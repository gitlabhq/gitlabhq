<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlTooltipDirective,
} from '@gitlab/ui';
import { convertArrayToCamelCase } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { I18N_USER_ACTIONS } from '../constants';
import { generateUserPaths } from '../utils';
import Actions from './actions';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    ...Actions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    },
    showButtonLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    userActions() {
      return convertArrayToCamelCase(this.user.actions);
    },
    dropdownActions() {
      return this.userActions.filter((a) => a !== 'edit');
    },
    dropdownDeleteActions() {
      return this.dropdownActions.filter((a) => a.includes('delete'));
    },
    dropdownSafeActions() {
      return this.dropdownActions.filter((a) => !this.dropdownDeleteActions.includes(a));
    },
    hasDropdownActions() {
      return this.dropdownActions.length > 0;
    },
    hasDeleteActions() {
      return this.dropdownDeleteActions.length > 0;
    },
    hasEditAction() {
      return this.userActions.includes('edit');
    },
    userPaths() {
      return generateUserPaths(this.paths, this.user.username);
    },
    editButtonAttrs() {
      return {
        'data-testid': 'edit',
        icon: 'pencil-square',
        href: this.userPaths.edit,
      };
    },
  },
  methods: {
    isLdapAction(action) {
      return action === 'ldapBlocked';
    },
    getActionComponent(action) {
      return Actions[capitalizeFirstCharacter(action)];
    },
  },
  i18n: I18N_USER_ACTIONS,
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-end gl-my-n2 gl-mx-n2"
    :data-testid="`user-actions-${user.id}`"
  >
    <div v-if="hasEditAction" class="gl-p-2">
      <gl-button v-if="showButtonLabels" v-bind="editButtonAttrs">{{
        $options.i18n.edit
      }}</gl-button>
      <gl-button
        v-else
        v-gl-tooltip="$options.i18n.edit"
        v-bind="editButtonAttrs"
        :aria-label="$options.i18n.edit"
      />
    </div>

    <div v-if="hasDropdownActions" class="gl-p-2">
      <gl-dropdown
        data-testid="dropdown-toggle"
        right
        :text="$options.i18n.userAdministration"
        :text-sr-only="!showButtonLabels"
        icon="settings"
        data-qa-selector="user_actions_dropdown_toggle"
        :data-qa-username="user.username"
      >
        <gl-dropdown-section-header>{{
          $options.i18n.userAdministration
        }}</gl-dropdown-section-header>

        <template v-for="action in dropdownSafeActions">
          <component
            :is="getActionComponent(action)"
            v-if="getActionComponent(action)"
            :key="action"
            :path="userPaths[action]"
            :username="user.name"
            :data-testid="action"
          >
            {{ $options.i18n[action] }}
          </component>
          <gl-dropdown-item v-else-if="isLdapAction(action)" :key="action" :data-testid="action">
            {{ $options.i18n[action] }}
          </gl-dropdown-item>
        </template>

        <gl-dropdown-divider v-if="hasDeleteActions" />

        <template v-for="action in dropdownDeleteActions">
          <component
            :is="getActionComponent(action)"
            v-if="getActionComponent(action)"
            :key="action"
            :paths="userPaths"
            :username="user.name"
            :oncall-schedules="user.oncallSchedules"
            :data-testid="`delete-${action}`"
          >
            {{ $options.i18n[action] }}
          </component>
        </template>
      </gl-dropdown>
    </div>
  </div>
</template>
