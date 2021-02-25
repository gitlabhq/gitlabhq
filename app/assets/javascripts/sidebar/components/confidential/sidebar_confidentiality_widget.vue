<script>
import produce from 'immer';
import Vue from 'vue';
import createFlash from '~/flash';
import { __, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { confidentialityQueries } from '~/sidebar/constants';
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
    event: 'click_edit_button',
    label: 'right_sidebar',
    property: 'confidentiality',
  },
  components: {
    SidebarEditableItem,
    SidebarConfidentialityContent,
    SidebarConfidentialityForm,
  },
  inject: ['fullPath', 'iid'],
  props: {
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
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.confidential || false;
      },
      error() {
        createFlash({
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
        // eslint-disable-next-line no-param-reassign
        draftData.workspace.issuable.confidential = !this.confidential;
      });

      client.writeQuery({
        query: confidentialityQueries[this.issuableType].query,
        variables: { fullPath: this.fullPath, iid: this.iid },
        data,
      });
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
  >
    <template #collapsed>
      <div>
        <sidebar-confidentiality-content v-if="!isLoading" :confidential="confidential" />
      </div>
    </template>
    <template #default>
      <sidebar-confidentiality-content :confidential="confidential" />
      <sidebar-confidentiality-form
        :confidential="confidential"
        :issuable-type="issuableType"
        @closeForm="closeForm"
      />
    </template>
  </sidebar-editable-item>
</template>
