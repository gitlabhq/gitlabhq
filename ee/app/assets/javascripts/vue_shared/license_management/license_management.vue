<script>
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import LicenseManagementRow from './components/license_management_row.vue';
import DeleteConfirmationModal from './components/delete_confirmation_modal.vue';
import createStore from './store/index';

const store = createStore();

export default {
  name: 'LicenseManagement',
  components: {
    DeleteConfirmationModal,
    LicenseManagementRow,
  },
  props: {
    apiUrl: {
      type: String,
      required: true,
    },
  },
  store,
  emptyMessage: s__(
    'LicenseManagement|There are currently no approved or blacklisted licenses in this project.',
  ),
  computed: {
    ...mapState(['managedLicenses', 'isLoadingManagedLicenses']),
  },
  mounted() {
    this.setAPISettings({
      apiUrlManageLicenses: this.apiUrl,
    });
    this.loadManagedLicenses();
  },
  methods: {
    ...mapActions(['setAPISettings', 'loadManagedLicenses']),
  },
};
</script>
<template>
  <div class="license-management">
    <delete-confirmation-modal/>
    <gl-loading-icon v-if="isLoadingManagedLicenses"/>
    <ul
      v-if="managedLicenses.length"
      class="list-group list-group-flush"
    >
      <license-management-row
        v-for="license in managedLicenses"
        :key="license.name"
        :license="license"
      />
    </ul>
    <div
      v-else
      class="bs-callout bs-callout-warning"
    >
      {{ $options.emptyMessage }}
    </div>
  </div>
</template>
