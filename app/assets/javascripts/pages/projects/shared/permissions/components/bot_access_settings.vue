<script>
import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import { s__ } from '~/locale';
import ProjectSettingRow from './project_setting_row.vue';

export default {
  name: 'BotAccessSettings',
  components: {
    GlFormCheckbox,
    GlFormInput,
    GroupSelect,
    ProjectSettingRow,
  },
  i18n: {
    botAccessLabel: s__('ProjectSettings|Security policy bot access'),
    botAccessEnabledLabel: s__(
      'ProjectSettings|Allow security policy bots to access CI/CD configuration files in this project.',
    ),
    botAccessEnabledHelpText: s__(
      'ProjectSettings|When enabled, security policy bots from projects in the same group hierarchy can access files matching the specified patterns.',
    ),
    botAccessFilePatternsLabel: s__('ProjectSettings|Allowed file patterns'),
    botAccessFilePatternsHelpText: s__(
      'ProjectSettings|Comma-separated glob patterns for files the bot can access (for example, ci/**/*.yml).',
    ),
    botAccessGroupLabel: s__('ProjectSettings|Allowed group'),
    botAccessGroupDescription: s__(
      'ProjectSettings|Restrict access to bots from projects in this group. If not set, defaults to the root ancestor group.',
    ),
    botAccessGroupEmptyText: s__('ProjectSettings|Use default (root ancestor group)'),
  },
  props: {
    enabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    filePatterns: {
      type: Array,
      required: false,
      default: () => [],
    },
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
    rootGroupId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      botAccessEnabled: this.enabled,
      botAccessFilePatterns: this.filePatterns,
    };
  },
  computed: {
    botAccessEnabledInputName() {
      return 'project[project_setting_attributes][pipeline_execution_policy_bot_access_enabled]';
    },
    botAccessFilePatternsInputName() {
      return 'project[project_setting_attributes][pipeline_execution_policy_bot_access_file_patterns][]';
    },
    filePatternsText: {
      get() {
        return (this.botAccessFilePatterns || []).join(', ');
      },
      set(value) {
        this.botAccessFilePatterns = value
          .split(',')
          .map((p) => p.trim())
          .filter(Boolean);
      },
    },
  },
};
</script>

<template>
  <project-setting-row data-testid="bot-access-settings">
    <label>
      <h5>{{ $options.i18n.botAccessLabel }}</h5>
      <input :value="botAccessEnabled" type="hidden" :name="botAccessEnabledInputName" />
      <gl-form-checkbox v-model="botAccessEnabled">
        {{ $options.i18n.botAccessEnabledLabel }}
        <template #help>
          {{ $options.i18n.botAccessEnabledHelpText }}
        </template>
      </gl-form-checkbox>
    </label>
    <div v-if="botAccessEnabled" class="gl-mt-3">
      <label for="bot-access-file-patterns">
        {{ $options.i18n.botAccessFilePatternsLabel }}
      </label>
      <input
        v-for="(pattern, index) in botAccessFilePatterns"
        :key="index"
        :value="pattern"
        type="hidden"
        :name="botAccessFilePatternsInputName"
      />
      <gl-form-input
        id="bot-access-file-patterns"
        v-model="filePatternsText"
        data-testid="bot-access-file-patterns-input"
      />
      <p class="gl-mt-2 gl-text-secondary">
        {{ $options.i18n.botAccessFilePatternsHelpText }}
      </p>
      <group-select
        class="gl-mt-3"
        :label="$options.i18n.botAccessGroupLabel"
        :description="$options.i18n.botAccessGroupDescription"
        :clearable="true"
        :initial-selection="groupId"
        :empty-text="$options.i18n.botAccessGroupEmptyText"
        :parent-group-i-d="rootGroupId ? String(rootGroupId) : null"
        :groups-filter="rootGroupId ? 'descendant_groups' : null"
        input-name="project[project_setting_attributes][pipeline_execution_policy_bot_access_group_id]"
        input-id="pipeline_execution_policy_bot_access_group_id"
        data-testid="bot-access-group-select"
      />
    </div>
  </project-setting-row>
</template>
