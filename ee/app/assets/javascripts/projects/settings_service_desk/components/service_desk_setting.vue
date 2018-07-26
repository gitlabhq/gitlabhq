<script>
  import tooltip from '~/vue_shared/directives/tooltip';
  import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
  import eventHub from '../event_hub';

  export default {
    name: 'ServiceDeskSetting',
    directives: {
      tooltip,
    },

    components: {
      ClipboardButton,
    },

    props: {
      isEnabled: {
        type: Boolean,
        required: true,
      },
      incomingEmail: {
        type: String,
        required: false,
        default: '',
      },
    },
    methods: {
      onCheckboxToggle(e) {
        const isChecked = e.target.checked;
        eventHub.$emit('serviceDeskEnabledCheckboxToggled', isChecked);
      },
    },
  };
</script>

<template>
  <div>
    <div class="form-check">
      <label for="service-desk-enabled-checkbox">
        <input
          id="service-desk-enabled-checkbox"
          ref="enabled-checkbox"
          :checked="isEnabled"
          type="checkbox"
          @change="onCheckboxToggle($event)"
        />
        <span class="descr">
          Activate Service Desk
        </span>
      </label>
    </div>
    <div
      v-if="isEnabled"
      class="panel-slim "
    >
      <div class="card-header">
        <h3 class="card-title">
          Forward external support email address to:
        </h3>
      </div>
      <div class="card-body">
        <template v-if="incomingEmail">
          <span
            ref="service-desk-incoming-email"
          >
            {{ incomingEmail }}
          </span>
          <clipboard-button
            :title="__('Copy incoming email address to clipboard')"
            :text="incomingEmail"
            css-class="btn btn-clipboard btn-transparent"
          />
        </template>
        <template v-else>
          <i
            class="fa fa-spinner fa-spin"
            aria-hidden="true">
          </i>
          <span class="sr-only">
            Fetching incoming email
          </span>
        </template>
      </div>
    </div>
  </div>
</template>
