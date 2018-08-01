<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import { mapActions, mapState } from 'vuex';
import GlModal from '~/vue_shared/components/gl_modal.vue';

export default {
  name: 'LicenseDeleteConfirmationModal',
  components: { GlModal },
  computed: {
    ...mapState(['currentLicenseInModal']),
    confirmationText() {
      const name = `<strong>${_.escape(this.currentLicenseInModal.name)}</strong>`;

      return sprintf(
        s__('LicenseManagement|You are about to remove the license, %{name}, from this project.'),
        { name },
        false,
      );
    },
  },
  methods: {
    ...mapActions(['resetLicenseInModal', 'deleteLicense']),
  },
};
</script>
<template>
  <gl-modal
    id="modal-license-delete-confirmation"
    :header-title-text="s__('LicenseManagement|Remove license?')"
    :footer-primary-button-text="s__('LicenseManagement|Remove license')"
    footer-primary-button-variant="danger"
    @cancel="resetLicenseInModal"
    @submit="deleteLicense(currentLicenseInModal)"
  >
    <span
      v-if="currentLicenseInModal"
      v-html="confirmationText"></span>
  </gl-modal>
</template>
