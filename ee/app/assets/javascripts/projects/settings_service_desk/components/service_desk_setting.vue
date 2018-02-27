<script>
  import tooltip from '~/vue_shared/directives/tooltip';
  import eventHub from '../event_hub';

  export default {
    name: 'ServiceDeskSetting',
    directives: {
      tooltip,
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
    <div class="checkbox">
      <label for="service-desk-enabled-checkbox">
        <input
          ref="enabled-checkbox"
          type="checkbox"
          id="service-desk-enabled-checkbox"
          :checked="isEnabled"
          @change="onCheckboxToggle($event)"
        />
        <span class="descr">
          Activate Service Desk
        </span>
      </label>
    </div>
    <div
      v-if="isEnabled"
      class="panel-slim panel-default"
    >
      <div class="panel-heading">
        <h3 class="panel-title">
          Forward external support email address to:
        </h3>
      </div>
      <div class="panel-body">
        <template v-if="incomingEmail">
          <span
            ref="service-desk-incoming-email"
          >
            {{ incomingEmail }}
          </span>
          <button
            v-tooltip
            type="button"
            class="btn btn-clipboard btn-transparent"
            title="Copy incoming email address to clipboard"
            :data-clipboard-text="incomingEmail"
          >
            <i
              class="fa fa-clipboard"
              aria-hidden="true">
            </i>
          </button>
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
