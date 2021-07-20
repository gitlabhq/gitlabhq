<script>
import {
  GlLink,
  GlButton,
  GlIcon,
  GlAvatar,
  GlTooltipDirective,
  GlTooltip,
  GlBadge,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { VISIBILITY_TYPE_ICON, GROUP_VISIBILITY_TYPE } from '~/groups/constants';
import csrf from '~/lib/utils/csrf';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';

export default {
  components: {
    GlIcon,
    GlAvatar,
    GlBadge,
    GlButton,
    GlTooltip,
    GlLink,
    UserAccessRoleBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { namespaces: null, isForking: false };
  },

  computed: {
    rowClass() {
      return {
        'has-description': this.group.description,
        'being-removed': this.isGroupPendingRemoval,
      };
    },
    isGroupPendingRemoval() {
      return this.group.marked_for_deletion;
    },
    hasForkedProject() {
      return Boolean(this.group.forked_project_path);
    },
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.group.visibility];
    },
    visibilityTooltip() {
      return GROUP_VISIBILITY_TYPE[this.group.visibility];
    },
    isSelectButtonDisabled() {
      return !this.group.can_create_project;
    },
  },

  methods: {
    fork() {
      this.isForking = true;
      this.$refs.form.submit();
    },
  },

  csrf,
};
</script>
<template>
  <li :class="rowClass" class="group-row">
    <div class="group-row-contents gl-display-flex gl-align-items-center gl-py-3 gl-pr-5">
      <div
        class="folder-toggle-wrap gl-mr-3 gl-display-flex gl-align-items-center gl-text-gray-500"
      >
        <gl-icon name="folder-o" />
      </div>
      <gl-link
        :href="group.relative_path"
        class="gl-display-none gl-flex-shrink-0 gl-sm-display-flex gl-mr-3"
      >
        <gl-avatar :size="32" shape="rect" :entity-name="group.name" :src="group.avatarUrl" />
      </gl-link>
      <div class="gl-min-w-0 gl-display-flex gl-flex-grow-1 gl-flex-shrink-1 gl-align-items-center">
        <div class="gl-min-w-0 gl-flex-grow-1 flex-shrink-1">
          <div class="title gl-display-flex gl-align-items-center gl-flex-wrap gl-mr-3">
            <gl-link :href="group.relative_path" class="gl-mt-3 gl-mr-3 gl-text-gray-900!">
              {{ group.full_name }}
            </gl-link>
            <gl-icon
              v-gl-tooltip.hover.bottom
              class="gl-display-inline-flex gl-mt-3 gl-mr-3 gl-text-gray-500"
              :name="visibilityIcon"
              :title="visibilityTooltip"
            />
            <gl-badge
              v-if="isGroupPendingRemoval"
              variant="warning"
              class="gl-display-none gl-sm-display-flex gl-mt-3 gl-mr-1"
              >{{ __('pending deletion') }}</gl-badge
            >
            <user-access-role-badge v-if="group.permission" class="gl-mt-3">
              {{ group.permission }}
            </user-access-role-badge>
          </div>
          <div v-if="group.description" class="description gl-line-height-20">
            <span v-safe-html="group.markdown_description"> </span>
          </div>
        </div>
        <div class="gl-display-flex gl-flex-shrink-0">
          <gl-button
            v-if="hasForkedProject"
            class="gl-h-7 gl-text-decoration-none!"
            :href="group.forked_project_path"
            >{{ __('Go to fork') }}</gl-button
          >
          <template v-else>
            <div ref="selectButtonWrapper">
              <form ref="form" method="POST" :action="group.fork_path">
                <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
                <gl-button
                  type="submit"
                  class="gl-h-7"
                  :data-qa-name="group.full_name"
                  category="secondary"
                  variant="success"
                  :disabled="isSelectButtonDisabled"
                  :loading="isForking"
                  @click="fork"
                  >{{ __('Select') }}</gl-button
                >
              </form>
            </div>
            <gl-tooltip v-if="isSelectButtonDisabled" :target="() => $refs.selectButtonWrapper">
              {{
                __('You must have permission to create a project in a namespace before forking.')
              }}
            </gl-tooltip>
          </template>
        </div>
      </div>
    </div>
  </li>
</template>
