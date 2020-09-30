<script>
import { mapState } from 'vuex';
import { GlTable } from '@gitlab/ui';
import { FIELDS } from '../constants';
import initUserPopovers from '~/user_popovers';
import MemberAvatar from './member_avatar.vue';
import MemberSource from './member_source.vue';
import CreatedAt from './created_at.vue';
import ExpiresAt from './expires_at.vue';
import MembersTableCell from './members_table_cell.vue';

export default {
  name: 'MembersTable',
  components: {
    GlTable,
    MemberAvatar,
    CreatedAt,
    ExpiresAt,
    MembersTableCell,
    MemberSource,
  },
  computed: {
    ...mapState(['members', 'tableFields']),
    filteredFields() {
      return FIELDS.filter(field => this.tableFields.includes(field.key));
    },
  },
  mounted() {
    initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
  },
};
</script>

<template>
  <gl-table
    class="members-table"
    head-variant="white"
    stacked="lg"
    :fields="filteredFields"
    :items="members"
    primary-key="id"
    thead-class="border-bottom"
    :empty-text="__('No members found')"
    show-empty
  >
    <template #cell(account)="{ item: member }">
      <members-table-cell #default="{ memberType }" :member="member">
        <member-avatar :member-type="memberType" :member="member" />
      </members-table-cell>
    </template>

    <template #cell(source)="{ item: member }">
      <members-table-cell #default="{ isDirectMember }" :member="member">
        <member-source :is-direct-member="isDirectMember" :member-source="member.source" />
      </members-table-cell>
    </template>

    <template #cell(granted)="{ item: { createdAt, createdBy } }">
      <created-at :date="createdAt" :created-by="createdBy" />
    </template>

    <template #cell(invited)="{ item: { createdAt, createdBy } }">
      <created-at :date="createdAt" :created-by="createdBy" />
    </template>

    <template #cell(requested)="{ item: { createdAt } }">
      <created-at :date="createdAt" />
    </template>

    <template #cell(expires)="{ item: { expiresAt } }">
      <expires-at :date="expiresAt" />
    </template>

    <template #head(actions)="{ label }">
      <span data-testid="col-actions" class="gl-sr-only">{{ label }}</span>
    </template>
  </gl-table>
</template>
