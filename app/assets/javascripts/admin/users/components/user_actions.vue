<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { convertArrayToCamelCase } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import { I18N_USER_ACTIONS } from '../constants';
import { generateUserPaths } from '../utils';
import Actions from './actions';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
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
        href: this.userPaths.edit,
      };
    },
    obstaclesForUserDeletion() {
      return parseUserDeletionObstacles(this.user);
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
  <div class="-gl-mx-2 -gl-my-2 gl-flex gl-justify-end" :data-testid="`user-actions-${user.id}`">
    <div v-if="hasEditAction" class="gl-p-2">
      <gl-button v-if="showButtonLabels" v-bind="editButtonAttrs">{{
        $options.i18n.edit
      }}</gl-button>
      <gl-button
        v-else
        v-gl-tooltip="$options.i18n.edit"
        icon="pencil-square"
        v-bind="editButtonAttrs"
        :aria-label="$options.i18n.edit"
      />
    </div>

    <div v-if="hasDropdownActions" class="gl-p-2">
      <gl-disclosure-dropdown
        icon="ellipsis_v"
        category="tertiary"
        :toggle-text="$options.i18n.userAdministration"
        text-sr-only
        data-testid="user-actions-dropdown-toggle"
        :data-qa-username="user.username"
        no-caret
        :auto-close="false"
      >
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
          <gl-disclosure-dropdown-item
            v-else-if="isLdapAction(action)"
            :key="action"
            :data-testid="action"
          >
            {{ $options.i18n[action] }}
          </gl-disclosure-dropdown-item>
        </template>

        <gl-disclosure-dropdown-group v-if="hasDeleteActions" bordered>
          <template v-for="action in dropdownDeleteActions">
            <component
              :is="getActionComponent(action)"
              v-if="getActionComponent(action)"
              :key="action"
              :paths="userPaths"
              :username="user.name"
              :user-id="user.id"
              :user-deletion-obstacles="obstaclesForUserDeletion"
              :data-testid="`delete-${action}`"
            >
              {{ $options.i18n[action] }}
            </component>
          </template>
        </gl-disclosure-dropdown-group>
      </gl-disclosure-dropdown>
    </div>
  </div>
</template>
