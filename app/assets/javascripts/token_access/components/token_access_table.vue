<script>
import {
  GlButton,
  GlIcon,
  GlLink,
  GlTable,
  GlLoadingIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { s__, __ } from '~/locale';
import { JOB_TOKEN_POLICIES } from '../constants';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlTable,
    GlLoadingIcon,
    GlSprintf,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    autopopulated: s__('CICD|Added from log.'),
  },
  inject: ['fullPath'],
  props: {
    items: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    // This can be removed after outbound_token_access.vue is removed, which is a deprecated feature. We need to hide
    // policies for that component, but show them on inbound_token_access.vue.
    showPolicies: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    fields() {
      const fullPath = {
        key: 'fullPath',
        label: s__('CICD|Group or project'),
        tdClass: this.showPolicies ? 'md:gl-w-3/5' : 'gl-w-full',
      };
      const policies = {
        key: 'jobTokenPolicies',
        label: s__('CICD|Job token permissions'),
        class: '!gl-align-middle md:gl-w-2/5',
      };
      const actions = {
        key: 'actions',
        label: __('Actions'),
        class: 'gl-text-right md:!gl-pl-0',
        tdClass: 'md:!gl-pb-0 md:!gl-pt-4',
      };

      return this.showPolicies ? [fullPath, policies, actions] : [fullPath, actions];
    },
  },
  methods: {
    itemType(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_GROUP ? 'group' : 'project';
    },
    getPolicies(policyKeys) {
      return policyKeys?.map((key) => JOB_TOKEN_POLICIES[key]);
    },
    hasJobTokenPolicies(item) {
      return Boolean(item.jobTokenPolicies?.length);
    },
    isCurrentProject(item) {
      return item.fullPath === this.fullPath;
    },
    shouldShowEditButton(item) {
      return this.showPolicies && !this.isCurrentProject(item);
    },
  },
};
</script>

<template>
  <gl-table :items="items" :fields="fields" :busy="loading" class="gl-mb-0" stacked="md">
    <template #table-busy>
      <gl-loading-icon size="md" />
    </template>
    <template #cell(fullPath)="{ item }">
      <div class="gl-inline-flex gl-items-center">
        <gl-icon
          :name="itemType(item)"
          class="gl-mr-3 gl-shrink-0"
          data-testid="token-access-icon"
        />
        <project-avatar
          :alt="item.name"
          :project-avatar-url="item.avatarUrl"
          :project-id="item.id"
          :project-name="item.name"
          class="gl-mr-3"
          :size="24"
          data-testid="token-access-avatar"
        />
        <gl-link :href="item.webUrl" data-testid="token-access-name">
          {{ item.fullPath }}
        </gl-link>
        <gl-icon
          v-if="item.autopopulated"
          v-gl-tooltip
          :title="$options.i18n.autopopulated"
          :aria-label="$options.i18n.autopopulated"
          name="log"
          class="gl-ml-3 gl-shrink-0"
          data-testid="autopopulated-icon"
        />
      </div>
    </template>

    <template #cell(jobTokenPolicies)="{ item }">
      <span v-if="item.defaultPermissions">
        {{ s__('CICD|Default (user membership and role)') }}</span
      >
      <span v-else-if="!hasJobTokenPolicies(item)">
        {{ s__('CICD|No resources selected (minimal access only)') }}</span
      >
      <ul v-else class="gl-m-0 gl-list-none gl-p-0 gl-leading-20">
        <li v-for="policy in getPolicies(item.jobTokenPolicies)" :key="policy.value">
          <gl-sprintf :message="s__('CICD|%{policy} to %{resource}')">
            <template #policy>{{ policy.text }}</template>
            <template #resource>{{ policy.resource.text }}</template>
          </gl-sprintf>
        </li>
      </ul>
    </template>

    <template #cell(actions)="{ item }">
      <div class="gl-flex gl-gap-2">
        <gl-button
          v-if="shouldShowEditButton(item)"
          icon="pencil"
          :aria-label="__('Edit')"
          data-testid="token-access-table-edit-button"
          @click="$emit('editItem', item)"
        />
        <gl-button
          v-if="!isCurrentProject(item)"
          icon="remove"
          :aria-label="__('Remove access')"
          data-testid="token-access-table-remove-button"
          @click="$emit('removeItem', item)"
        />
      </div>
    </template>
  </gl-table>
</template>
