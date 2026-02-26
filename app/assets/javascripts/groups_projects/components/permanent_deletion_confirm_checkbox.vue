<script>
import { GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'PermanentDeletionConfirmCheckbox',
  components: { GlFormCheckbox, GlSprintf, GlLink },
  model: {
    prop: 'checked',
    event: 'change',
  },
  resourceStrings: {
    [RESOURCE_TYPES.PROJECT]: {
      exportHelpPath: helpPagePath('user/project/settings/import_export', {
        anchor: 'export-a-project-and-its-data',
      }),
      checkboxMessage: s__(
        'Projects|This action permanently deletes this project and all its data. Your administrator cannot restore it. %{linkStart}View data export options.%{linkEnd}',
      ),
    },
    [RESOURCE_TYPES.GROUP]: {
      exportHelpPath: helpPagePath('user/project/settings/import_export', {
        anchor: 'export-a-group',
      }),
      checkboxMessage: s__(
        'Groups|This action permanently deletes this group and all its data. Your administrator cannot restore it. %{linkStart}View data export options.%{linkEnd}',
      ),
    },
  },
  props: {
    resourceType: {
      type: String,
      required: true,
      validator: (value) => Object.values(RESOURCE_TYPES).includes(value),
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['change'],
  computed: {
    i18n() {
      return this.$options.resourceStrings[this.resourceType];
    },
  },
  methods: {
    handleChange(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <gl-form-checkbox :checked="checked" @input="handleChange">
    <gl-sprintf :message="i18n.checkboxMessage">
      <template #link="{ content }">
        <gl-link :href="i18n.exportHelpPath" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-form-checkbox>
</template>
