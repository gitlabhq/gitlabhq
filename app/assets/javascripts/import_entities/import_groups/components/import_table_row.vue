<script>
import { GlButton, GlIcon, GlLink, GlFormInput } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';

export default {
  components: {
    Select2Select,
    ImportStatus,
    GlButton,
    GlLink,
    GlIcon,
    GlFormInput,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    availableNamespaces: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isDisabled() {
      return this.group.status !== STATUSES.NONE;
    },

    isFinished() {
      return this.group.status === STATUSES.FINISHED;
    },

    select2Options() {
      return {
        data: this.availableNamespaces.map((namespace) => ({
          id: namespace.full_path,
          text: namespace.full_path,
        })),
      };
    },
  },
  methods: {
    getPath(group) {
      return `${group.import_target.target_namespace}/${group.import_target.new_name}`;
    },

    getFullPath(group) {
      return joinPaths(gon.relative_url_root || '/', this.getPath(group));
    },
  },
};
</script>

<template>
  <tr class="gl-border-gray-200 gl-border-0 gl-border-b-1">
    <td class="gl-p-4">
      <gl-link :href="group.web_url" target="_blank">
        {{ group.full_path }} <gl-icon name="external-link" />
      </gl-link>
    </td>
    <td class="gl-p-4">
      <gl-link v-if="isFinished" :href="getFullPath(group)">{{ getPath(group) }}</gl-link>

      <div
        v-else
        class="import-entities-target-select gl-display-flex gl-align-items-stretch"
        :class="{
          disabled: isDisabled,
        }"
      >
        <select2-select
          :disabled="isDisabled"
          :options="select2Options"
          :value="group.import_target.target_namespace"
          @input="$emit('update-target-namespace', $event)"
        />
        <div
          class="import-entities-target-select-separator gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1"
        >
          /
        </div>
        <gl-form-input
          class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
          :disabled="isDisabled"
          :value="group.import_target.new_name"
          @input="$emit('update-new-name', $event)"
        />
      </div>
    </td>
    <td class="gl-p-4 gl-white-space-nowrap">
      <import-status :status="group.status" />
    </td>
    <td class="gl-p-4">
      <gl-button
        v-if="!isDisabled"
        variant="success"
        category="secondary"
        @click="$emit('import-group')"
        >{{ __('Import') }}</gl-button
      >
    </td>
  </tr>
</template>
