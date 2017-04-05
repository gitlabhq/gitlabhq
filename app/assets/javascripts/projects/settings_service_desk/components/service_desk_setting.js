import ClipboardAction from 'clipboard/lib/clipboard-action';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskSetting',

  props: {
    isActivated: {
      type: Boolean,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    fetchError: {
      type: Object,
      required: false,
      default: null,
    },
  },

  methods: {
    onCheckboxToggle(e) {
      const isChecked = e.target.checked;
      eventHub.$emit('serviceDeskEnabledCheckboxToggled', isChecked);
    },
    copyIncomingEmail(e) {
      e.preventDefault();

      const clipboardAction = new ClipboardAction({
        action: 'copy',
        target: this.$refs['service-desk-incoming-email'],
        text: this.incomingEmail,
        trigger: e,
        emitter: { emit: () => {} },
      });

      clipboardAction.destroy();
    },
  },

  template: `
    <div>
      <div class="checkbox">
        <label for="service-desk-enabled-checkbox">
          <input
            type="checkbox"
            id="service-desk-enabled-checkbox"
            :checked="isActivated"
            @change="onCheckboxToggle($event)">
          <span class="descr">
            Activate service desk
          </span>
        </label>
      </div>
      <template v-if="isActivated">
        <div
          class="panel-slim panel-default">
          <div class="panel-heading">
            <h3 class="panel-title">
              Forward external support email address to:
            </h3>
          </div>
          <div class="panel-body">
            <template v-if="fetchError">
              <i class="fa fa-exclamation-circle" aria-hidden="true" />
              An error occurred while fetching the incoming email
            </template>
            <template v-else-if="incomingEmail">
              <span ref="service-desk-incoming-email">
                {{ incomingEmail }}
              </span>
              <button
                class="btn btn-clipboard btn-transparent"
                title="Copy incoming email address to clipboard"
                @click="copyIncomingEmail($event)">
                <i class="fa fa-clipboard" aria-hidden="true" />
              </button>
            </template>
            <template v-else>
              <i class="fa fa-spinner fa-spin" aria-hidden="true" />
              <span class="sr-only">
                Fetching incoming email
              </span>
            </template>
          </div>
        </div>
        <p class="settings-message">
          We recommend you protect the external support email address.
          Unblocked email spam would result in many spam issues being created,
          and may disrupt your GitLab service.
        </p>
      </template>
    </div>
  `,
};
