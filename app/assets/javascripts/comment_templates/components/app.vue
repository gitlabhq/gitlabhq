<script>
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

export default {
  name: 'CommentTemplatesApp',
  components: {
    SettingsSection,
  },
};
</script>

<template>
  <settings-section :heading="__('Comment templates')">
    <template #description>
      {{
        __(
          'Comment templates can be used when creating comments inside issues, merge requests, and epics.',
        )
      }}
    </template>

    <keep-alive><router-view /></keep-alive>
  </settings-section>
</template>
