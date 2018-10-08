<script>
import { Button } from '@gitlab-org/gitlab-ui';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import AddLicenseFormDropdown from './add_license_form_dropdown.vue';
import { s__ } from '~/locale';

export default {
  name: 'AddLicenseForm',
  components: {
    AddLicenseFormDropdown,
    glButton: Button,
  },
  LICENSE_APPROVAL_STATUS,
  approvalStatusOptions: [
    { value: LICENSE_APPROVAL_STATUS.APPROVED, label: s__('LicenseManagement|Approve') },
    { value: LICENSE_APPROVAL_STATUS.BLACKLISTED, label: s__('LicenseManagement|Blacklist') },
  ],
  props: {
    managedLicenses: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      approvalStatus: '',
      licenseName: '',
    };
  },
  computed: {
    isInvalidLicense() {
      return this.managedLicenses.some(({ name }) => name === this.licenseName);
    },
    submitDisabled() {
      return this.isInvalidLicense || this.licenseName.trim() === '' || this.approvalStatus === '';
    },
  },
  methods: {
    addLicense() {
      this.$emit('addLicense', {
        newStatus: this.approvalStatus,
        license: { name: this.licenseName },
      });
      this.closeForm();
    },
    closeForm() {
      this.$emit('closeForm');
    },
  },
};
</script>
<template>
  <div class="col-sm-6 js-add-license-form">
    <div class="form-group">
      <label
        class="label-bold"
        for="js-license-dropdown"
      >
        {{ s__('LicenseManagement|Add licenses manually to approve or blacklist') }}
      </label>
      <add-license-form-dropdown
        id="js-license-dropdown"
        v-model="licenseName"
        :placeholder="s__('LicenseManagement|License name')"
      />
      <div
        class="invalid-feedback"
        :class="{'d-block': isInvalidLicense}"
      >
        {{ s__('LicenseManagement|This license already exists in this project.') }}
      </div>
    </div>
    <div class="form-group">
      <div
        v-for="option in $options.approvalStatusOptions"
        :key="option.value"
        class="form-check"
      >
        <input
          :id="`js-${option.value}-license-radio`"
          v-model="approvalStatus"
          class="form-check-input"
          type="radio"
          :value="option.value"
        />
        <label
          :for="`js-${option.value}-license-radio`"
          class="form-check-label"
        >
          {{ option.label }}
        </label>
      </div>
    </div>
    <gl-button
      class="js-submit"
      variant="default"
      :disabled="submitDisabled"
      @click="addLicense"
    >
      {{ s__('LicenseManagement|Submit') }}
    </gl-button>
    <gl-button
      class="js-cancel"
      variant="default"
      @click="closeForm"
    >
      {{ s__('LicenseManagement|Cancel') }}
    </gl-button>
  </div>
</template>
