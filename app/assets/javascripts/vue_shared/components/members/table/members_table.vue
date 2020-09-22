<script>
import { mapState } from 'vuex';
import { GlTable } from '@gitlab/ui';
import { FIELDS } from '../constants';
import initUserPopovers from '~/user_popovers';

export default {
  name: 'MembersTable',
  components: {
    GlTable,
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
    <template #cell(source)>
      <!-- Temporarily empty -->
    </template>

    <template #head(actions)="{ label }">
      <span data-testid="col-actions" class="gl-sr-only">{{ label }}</span>
    </template>
  </gl-table>
</template>
