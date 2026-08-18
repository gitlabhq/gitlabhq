<script>
import { GlAttributeList, GlAlert } from '@gitlab/ui';
import { intersectionWith } from 'lodash-es';
import { s__, n__ } from '~/locale';
import { relativePathToAbsolute, getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { organizationsPath } from '~/lib/utils/path_helpers/organizations';
import BaseStep from './base_step.vue';

const LIST_ITEM_TYPE_NAME = 'name';
const LIST_ITEM_TYPE_URL = 'url';
const LIST_ITEM_TYPE_TLGS = 'tlgs';
const LIST_ITEM_TYPE_ADMINS = 'admins';

export default {
  name: 'ReconciliationStep3',
  LIST_ITEM_TYPE_NAME,
  LIST_ITEM_TYPE_URL,
  LIST_ITEM_TYPE_TLGS,
  LIST_ITEM_TYPE_ADMINS,
  components: {
    GlAttributeList,
    GlAlert,
    BaseStep,
  },
  inheritAttrs: false,
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  computed: {
    adminNames() {
      const ownersFromAllGroups = this.organization.groups.nodes.map(
        (group) => group.groupMembers.nodes,
      );

      // Intersection of all owners to match the logic in
      // app/services/organizations/transfer/organization_users_service.rb
      return intersectionWith(
        ...ownersFromAllGroups,
        (owner1, owner2) => owner1.user.id === owner2.user.id,
      ).map((admin) => admin.user.name);
    },
    attributeListItems() {
      const name = {
        type: LIST_ITEM_TYPE_NAME,
        label: s__('Organization|Organization name'),
        text: this.organization.name,
      };

      const url = {
        type: LIST_ITEM_TYPE_URL,
        label: s__('Organization|URL'),
        text: relativePathToAbsolute(
          joinPaths(organizationsPath(), this.organization.path),
          getBaseURL(),
        ),
      };

      const tlgs = {
        type: LIST_ITEM_TYPE_TLGS,
        label: s__('Organization|Top-level groups'),
        text: n__(
          'Organization|%d top-level group',
          'Organization|%d top-level groups',
          this.organization.groups.nodes.length,
        ),
      };

      const admins = {
        type: LIST_ITEM_TYPE_ADMINS,
        label: s__('Organization|Organization administrators'),
        text: this.adminNames.join(', '),
      };

      return [name, url, tlgs, admins];
    },
  },
};
</script>

<template>
  <base-step :title="s__('Organization|Confirm your organization')">
    <template #description>
      <p>
        {{
          s__(
            'Organization|After you confirm your organization structure, your data will be transferred to your organization.',
          )
        }}
      </p>
    </template>
    <div class="gl-mx-auto gl-w-full gl-max-w-xl">
      <p class="gl-font-bold">{{ s__('Organization|You are confirming:') }}</p>
      <div class="gl-border gl-rounded-lg gl-bg-gray-10 gl-px-5">
        <gl-attribute-list
          class="organizations-reconciliation-step-3-attributes-list gl-mb-0 gl-grid-flow-row gl-grid-cols-none"
          :items="attributeListItems"
        >
          <template #description="{ item }">
            <template
              v-if="[$options.LIST_ITEM_TYPE_NAME, $options.LIST_ITEM_TYPE_URL].includes(item.type)"
            >
              {{ item.text }}
              <div class="gl-mt-2 gl-text-secondary">
                {{ s__('Organization|Editable later from your Organization page') }}
              </div>
            </template>
          </template>
        </gl-attribute-list>
      </div>
      <gl-alert class="gl-mt-5" :dismissible="false">
        <span class="gl-font-bold">{{ s__('Organization|After confirmation, you cannot:') }}</span>
        <ul class="gl-m-0 gl-mt-5 gl-pl-5">
          <li>{{ s__('Organization|Delete the organization') }}</li>
          <li>
            {{
              s__(
                'Organization|Remove or add top-level groups. Contact support if you must make changes.',
              )
            }}
          </li>
        </ul>
      </gl-alert>
    </div>
  </base-step>
</template>
