import $ from 'jquery';
import { escape } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { backOff } from '~/lib/utils/common_utils';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { __ } from '~/locale';
import AUTH_METHOD from './constants';

export default class SSHMirror {
  constructor(formSelector) {
    this.backOffRequestCounter = 0;

    this.$form = $(formSelector);

    this.$repositoryUrl = this.$form.find('.js-repo-url');
    this.$knownHosts = this.$form.find('.js-known-hosts');

    this.$sectionSSHHostKeys = this.$form.find('.js-ssh-host-keys-section');
    this.$hostKeysInformation = this.$form.find('.js-fingerprint-ssh-info');
    this.$btnDetectHostKeys = this.$form.find('.js-detect-host-keys');
    this.$btnSSHHostsShowAdvanced = this.$form.find('.btn-show-advanced');
    this.$dropdownAuthType = this.$form.find('.js-mirror-auth-type');
    this.$hiddenAuthType = this.$form.find('.js-hidden-mirror-auth-type');

    this.$wellPasswordAuth = this.$form.find('.js-well-password-auth');
  }

  init() {
    this.handleRepositoryUrlInput(true);

    this.$repositoryUrl.on('keyup', () => this.handleRepositoryUrlInput());
    this.$knownHosts.on('keyup', (e) => this.handleSSHKnownHostsInput(e));
    this.$dropdownAuthType.on('change', (e) => this.handleAuthTypeChange(e));
    this.$btnDetectHostKeys.on('click', (e) => this.handleDetectHostKeys(e));
    this.$btnSSHHostsShowAdvanced.on('click', (e) => this.handleSSHHostsAdvanced(e));
  }

  /**
   * Method to monitor Git Repository URL input
   */
  handleRepositoryUrlInput(forceMatch) {
    const protocol = this.$repositoryUrl.val().split('://')[0];
    const protRegEx = /http|git/;

    // Validate URL and verify if it consists only supported protocols
    if (forceMatch || this.$form.get(0).checkValidity()) {
      const isSsh = protocol === 'ssh';
      // Hide/Show SSH Host keys section only for SSH URLs
      this.$sectionSSHHostKeys.collapse(isSsh ? 'show' : 'hide');
      this.$btnDetectHostKeys.enable();

      // Verify if URL is http, https or git and hide/show Auth type dropdown
      // as we don't support auth type SSH for non-SSH URLs
      const matchesProtocol = protRegEx.test(protocol);
      this.$dropdownAuthType.attr('disabled', matchesProtocol);

      if (forceMatch && isSsh) {
        this.$dropdownAuthType.val(AUTH_METHOD.SSH);
        this.toggleAuthWell(AUTH_METHOD.SSH);
      } else {
        this.$dropdownAuthType.val(AUTH_METHOD.PASSWORD);
        this.toggleAuthWell(AUTH_METHOD.PASSWORD);
      }
    }
  }

  /**
   * Click event handler to detect SSH Host key and fingerprints from
   * provided Git Repository URL.
   */
  handleDetectHostKeys() {
    const projectMirrorSSHEndpoint = this.$form.data('project-mirror-ssh-endpoint');
    const repositoryUrl = this.$repositoryUrl.val();
    const currentKnownHosts = this.$knownHosts.val();
    const $btnLoadSpinner = this.$btnDetectHostKeys.find('.js-spinner');

    // Disable button while we make request
    this.$btnDetectHostKeys.disable();
    $btnLoadSpinner.removeClass('gl-hidden');

    // Make backOff polling to get data
    backOff((next, stop) => {
      axios
        .get(
          `${projectMirrorSSHEndpoint}?ssh_url=${repositoryUrl}&compare_host_keys=${encodeURIComponent(
            currentKnownHosts,
          )}`,
        )
        .then(({ data, status }) => {
          if (status === HTTP_STATUS_NO_CONTENT) {
            this.backOffRequestCounter += 1;
            if (this.backOffRequestCounter < 3) {
              next();
            } else {
              stop(data);
            }
          } else {
            stop(data);
          }
        })
        .catch(stop);
    })
      .then((res) => {
        $btnLoadSpinner.addClass('gl-hidden');
        // Once data is received, we show verification info along with Host keys and fingerprints
        this.$hostKeysInformation
          .find('.js-fingerprint-verification')
          .collapse(res.host_keys_changed ? 'hide' : 'show');
        if (res.known_hosts && res.fingerprints) {
          this.showSSHInformation(res);
        }
      })
      .catch(({ response }) => {
        // Show failure message when there's an error and re-enable Detect host keys button
        const failureMessage = response.data
          ? response.data.message
          : __('An error occurred while detecting host keys');
        createAlert({
          message: failureMessage,
        });

        $btnLoadSpinner.addClass('hidden');
        this.$btnDetectHostKeys.enable();
      });
  }

  /**
   * Method to monitor known hosts textarea input
   */
  handleSSHKnownHostsInput() {
    // Strike-out fingerprints and remove verification info if `known hosts` value is altered
    this.$hostKeysInformation.find('.js-fingerprints-list').addClass('invalidate');
    this.$hostKeysInformation.find('.js-fingerprint-verification').collapse('hide');
  }

  /**
   * Click event handler for `Show advanced` button under SSH Host keys section
   */
  handleSSHHostsAdvanced() {
    const $knownHost = this.$sectionSSHHostKeys.find('.js-ssh-known-hosts');
    const toggleShowAdvanced = $knownHost.hasClass('show');

    $knownHost.collapse('toggle');
    this.$btnSSHHostsShowAdvanced.toggleClass('show-advanced', toggleShowAdvanced);
  }

  /**
   * Authentication method dropdown change event listener
   */
  handleAuthTypeChange() {
    const selectedAuthType = this.$dropdownAuthType.val();

    this.$wellPasswordAuth.collapse('hide');
    this.updateHiddenAuthType(selectedAuthType);
    this.toggleAuthWell(selectedAuthType);
  }

  /**
   * Method to parse SSH Host keys data and render it
   * under SSH host keys section
   */
  showSSHInformation(sshHostKeys) {
    const $fingerprintsList = this.$hostKeysInformation.find('.js-fingerprints-list');
    let fingerprints = '';
    sshHostKeys.fingerprints.forEach((fingerprint) => {
      const escFingerprints = escape(fingerprint.fingerprint_sha256 || fingerprint.fingerprint);
      fingerprints += `<code>${escFingerprints}</code>`;
    });

    this.$hostKeysInformation.collapse('show');
    $fingerprintsList.removeClass('invalidate');
    $fingerprintsList.html(fingerprints);
    this.$sectionSSHHostKeys.find('.js-known-hosts').val(sshHostKeys.known_hosts);
  }

  /**
   * Toggle Auth type information container based on provided `authType`
   */
  toggleAuthWell(authType) {
    this.$wellPasswordAuth.collapse(authType === AUTH_METHOD.PASSWORD ? 'show' : 'hide');
    this.updateHiddenAuthType(authType);
  }

  updateHiddenAuthType(authType) {
    this.$hiddenAuthType.val(authType);
    this.$hiddenAuthType.prop('disabled', authType === AUTH_METHOD.SSH);
  }

  destroy() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$repositoryUrl.off('keyup');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$form.find('.js-known-hosts').off('keyup');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$dropdownAuthType.off('change');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$btnDetectHostKeys.off('click');
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.$btnSSHHostsShowAdvanced.off('click');
  }
}
