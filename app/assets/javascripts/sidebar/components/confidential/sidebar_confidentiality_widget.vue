<script>
import produce from 'immer';
import Vue from 'vue';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { Tracking } from '../../constants';
import { confidentialityQueries } from '../../queries/constants';
import SidebarEditableItem from '../sidebar_editable_item.vue';
import SidebarConfidentialityContent from './sidebar_confidentiality_content.vue';
import SidebarConfidentialityForm from './sidebar_confidentiality_form.vue';

export const confidentialWidget = Vue.observable({
  setConfidentiality: null,
});

const hideDropdownEvent = new CustomEvent('hiddenGlDropdown', {
  bubbles: true,
});

export default {
  tracking: {
    event: Tracking.editEvent,
    label: Tracking.rightSidebarLabel,
    property: 'confidentiality',
  },
  components: {
    SidebarEditableItem,
    SidebarConfidentialityContent,
    SidebarConfidentialityForm,
  },
  inject: {
    isClassicSidebar: {
      default: false,
    },
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      confidential: false,
    };
  },
  apollo: {
    confidential: {
      query() {
        return confidentialityQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable?.confidential || false;
      },
      skip() {
        return !this.iid;
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.$emit('confidentialityUpdated', data.workspace?.issuable?.confidential);
      },
      error() {
        createAlert({
          message: sprintf(
            __('Something went wrong while setting %{issuableType} confidentiality.'),
            {
              issuableType: this.issuableType,
            },
          ),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.confidential.loading;
    },
  },
  mounted() {
    confidentialWidget.setConfidentiality = this.setConfidentiality;
  },
  destroyed() {
    confidentialWidget.setConfidentiality = null;
  },
  methods: {
    closeForm() {
      this.$refs.editable.collapse();
      this.$el.dispatchEvent(hideDropdownEvent);
      this.$emit('closeForm');
    },
    // synchronizing the quick action with the sidebar widget
    // this is a temporary solution until we have confidentiality real-time updates
    setConfidentiality() {
      const { defaultClient: client } = this.$apollo.provider.clients;
      const sourceData = client.readQuery({
        query: confidentialityQueries[this.issuableType].query,
        variables: { fullPath: this.fullPath, iid: this.iid },
      });

      const data = produce(sourceData, (draftData) => {
        draftData.workspace.issuable.confidential = !this.confidential;
      });

      client.writeQuery({
        query: confidentialityQueries[this.issuableType].query,
        variables: { fullPath: this.fullPath, iid: this.iid },
        data,
      });
    },
    expandSidebar() {
      this.$refs.editable.expand();
      this.$emit('expandSidebar');
    },
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="__('Confidentiality')"
    :tracking="$options.tracking"
    :loading="isLoading"
    class="block confidentiality"
    data-testid="sidebar-confidentiality"
  >
    <template #collapsed>
      <div>
        <sidebar-confidentiality-content
          v-if="!isLoading"
          :confidential="confidential"
          :issuable-type="issuableType"
          :class="{ 'gl-mt-3': !isClassicSidebar }"
          @expandSidebar="expandSidebar"
        />
      </div>
    </template>
    <template #default>
      <sidebar-confidentiality-content :confidential="confidential" :issuable-type="issuableType" />
      <sidebar-confidentiality-form
        :iid="iid"
        :full-path="fullPath"
        :confidential="confidential"
        :issuable-type="issuableType"
        @closeForm="closeForm"
      />
    </template>
  </sidebar-editable-item>
</template>
