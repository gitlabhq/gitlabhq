<script>
import { mapActions } from 'vuex';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { getIssueStatusFromLicenseStatus } from 'ee/vue_shared/license_management/store/utils';

import { LICENSE_APPROVAL_STATUS } from '../constants';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

export default {
  name: 'LicenseManagementRow',
  components: {
    Icon,
    IssueStatusIcon,
  },
  props: {
    license: {
      type: Object,
      required: true,
      validator: license =>
        !!license.name && Object.values(LICENSE_APPROVAL_STATUS).includes(license.approvalStatus),
    },
  },
  LICENSE_APPROVAL_STATUS,
  [LICENSE_APPROVAL_STATUS.APPROVED]: s__('LicenseManagement|Approved'),
  [LICENSE_APPROVAL_STATUS.BLACKLISTED]: s__('LicenseManagement|Blacklisted'),
  computed: {
    approveIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.APPROVED
        ? visibleClass
        : invisibleClass;
    },
    blacklistIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.BLACKLISTED
        ? visibleClass
        : invisibleClass;
    },
    status() {
      return getIssueStatusFromLicenseStatus(this.license.approvalStatus);
    },
    dropdownText() {
      return this.$options[this.license.approvalStatus];
    },
  },
  methods: {
    ...mapActions(['setLicenseInModal', 'approveLicense', 'blacklistLicense']),
  },
};
</script>
<template>
  <li class="list-group-item">
    <issue-status-icon
      :status="status"
      class="float-left append-right-default"
    />
    <span class="js-license-name">{{ license.name }}</span>
    <div class="float-right">
      <div class="d-flex">
        <div class="dropdown">
          <button
            class="btn btn-secondary dropdown-toggle"
            type="button"
            data-toggle="dropdown"
            aria-haspopup="true"
            aria-expanded="false"
          >
            {{ dropdownText }}
            <icon
              class="float-right"
              name="chevron-down"
            />
          </button>
          <div
            class="dropdown-menu dropdown-menu-right"
          >
            <button
              class="dropdown-item"
              type="button"
              @click="approveLicense(license)"
            >
              <icon
                :class="approveIconClass"
                name="mobile-issue-close"
              />
              {{ $options[$options.LICENSE_APPROVAL_STATUS.APPROVED] }}
            </button>
            <button
              class="dropdown-item"
              type="button"
              @click="blacklistLicense(license)"
            >
              <icon
                :class="blacklistIconClass"
                name="mobile-issue-close"
              />
              {{ $options[$options.LICENSE_APPROVAL_STATUS.BLACKLISTED] }}
            </button>
          </div>
        </div>
        <button
          class="btn btn-blank js-remove-button"
          type="button"
          data-toggle="modal"
          data-target="#modal-license-delete-confirmation"
          @click="setLicenseInModal(license)"
        >
          <icon name="remove"/>
        </button>
      </div>
    </div>
  </li>
</template>
