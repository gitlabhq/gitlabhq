<script>
import { GlAlert, GlButton, GlModal, GlTable, GlTooltipDirective } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { updateApplicationSettings } from '~/rest_api';
import { logError } from '~/lib/logger';
import toast from '~/vue_shared/plugins/global_toast';
import { __, s__, sprintf } from '~/locale';
import { MAX_CLIENTS } from './constants';
import ClientForm from './client_form.vue';

// A template is omitted rather than sent as an empty string: the setting's schema
// requires at least one template key and gives every present key a minimum length,
// so an empty one is rejected instead of read as "not set".
const buildEntry = (entry = {}) => {
  const built = { name: entry.name || '' };

  if (entry.ssh_url_template) built.ssh_url_template = entry.ssh_url_template;
  if (entry.http_url_template) built.http_url_template = entry.http_url_template;

  return built;
};

export default {
  name: 'CodeDropdownClientsApp',
  components: { GlAlert, GlButton, GlModal, GlTable, CrudComponent, ClientForm },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    initialClients: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      clients: this.initialClients.map(buildEntry),
      editedIndex: null,
      pendingDeleteIndex: null,
      isSaving: false,
      errorMessage: '',
      // Server-side messages that could not be tied to a field, shown above the list.
      formErrors: [],
    };
  },
  computed: {
    canAdd() {
      return this.clients.length < MAX_CLIENTS;
    },
    editedClient() {
      return this.editedIndex === null ? null : this.clients[this.editedIndex];
    },
    // Every entry except the one being edited, so the form can flag duplicate
    // names and templates without the edited entry colliding with itself.
    otherClients() {
      return this.clients.filter((_, index) => index !== this.editedIndex);
    },
    pendingDeleteName() {
      return this.pendingDeleteIndex === null ? '' : this.clients[this.pendingDeleteIndex].name;
    },
    deleteModalTitle() {
      return s__('CodeDropdownClients|Delete code dropdown client?');
    },
    deleteModalBody() {
      return sprintf(
        s__('CodeDropdownClients|You are about to delete the %{name} client.'),
        { name: this.pendingDeleteName },
        false,
      );
    },
  },
  methods: {
    showAddForm(showForm) {
      this.editedIndex = null;
      showForm();
    },
    showEditForm(index, showForm) {
      this.editedIndex = index;
      showForm();
    },
    cancelForm(hideForm) {
      this.editedIndex = null;
      hideForm();
    },
    // The setting is a single JSON column, so every action sends the whole list
    // and the component only keeps the new one once the request succeeds.
    async persist(clients) {
      this.isSaving = true;
      this.errorMessage = '';
      this.formErrors = [];

      try {
        await updateApplicationSettings({ code_dropdown_custom_clients: clients });
        this.clients = clients;
        toast(s__('CodeDropdownClients|Code dropdown clients updated.'));
        return true;
      } catch (error) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Failed to update code dropdown clients. See error info:', error);
        this.setServerErrors(error);
        return false;
      } finally {
        this.isSaving = false;
      }
    },
    // Model validation failures come back under `message` keyed by attribute, while
    // parameter validation failures come back as a plain `error` string.
    setServerErrors(error) {
      const data = error?.response?.data;
      const messages = data?.message?.code_dropdown_custom_clients;

      if (Array.isArray(messages) && messages.length) {
        this.formErrors = messages;
        return;
      }

      this.errorMessage =
        [data?.message, data?.error].find((value) => typeof value === 'string' && value) ||
        s__('CodeDropdownClients|An unknown error occurred. Please try again.');
    },
    async submitClient(entry, hideForm) {
      const clients = [...this.clients];

      if (this.editedIndex === null) {
        clients.push(buildEntry(entry));
      } else {
        clients.splice(this.editedIndex, 1, buildEntry(entry));
      }

      if (await this.persist(clients)) {
        this.editedIndex = null;
        hideForm();
      }
    },
    confirmDelete(index) {
      this.pendingDeleteIndex = index;
      this.$refs.deleteModal.show();
    },
    async deleteClient() {
      const clients = this.clients.filter((_, index) => index !== this.pendingDeleteIndex);

      await this.persist(clients);

      this.pendingDeleteIndex = null;
      this.editedIndex = null;
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('CodeDropdownClients|Client name'),
      tdClass: '!gl-align-middle !gl-py-3',
    },
    {
      key: 'actions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: '!gl-align-middle !gl-py-3 gl-text-right',
    },
  ],
  i18n: {
    title: s__('CodeDropdownClients|Code dropdown clients'),
    description: s__(
      'CodeDropdownClients|Add custom "Open with" entries to the project Code dropdown for all users on this instance. GitLab can\'t verify these applications, so add only clients you trust.',
    ),
    addClient: s__('CodeDropdownClients|Add client'),
    editClient: s__('CodeDropdownClients|Edit client'),
    deleteClient: s__('CodeDropdownClients|Delete client'),
    empty: s__('CodeDropdownClients|No clients have been added.'),
  },
  deleteModalActions: {
    primary: { text: s__('CodeDropdownClients|Delete client'), attributes: { variant: 'danger' } },
    cancel: { text: __('Cancel') },
  },
  MAX_CLIENTS,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorMessage"
      variant="danger"
      class="gl-mb-3"
      data-testid="error-alert"
      @dismiss="errorMessage = ''"
    >
      {{ errorMessage }}
    </gl-alert>

    <gl-alert
      v-if="formErrors.length"
      variant="danger"
      class="gl-mb-3"
      data-testid="validation-alert"
      @dismiss="formErrors = []"
    >
      <ul class="gl-m-0 gl-pl-5">
        <li v-for="message in formErrors" :key="message">{{ message }}</li>
      </ul>
    </gl-alert>

    <crud-component
      :title="$options.i18n.title"
      :count="clients.length"
      icon="code"
      show-zero-count
    >
      <template #description>
        {{ $options.i18n.description }}
      </template>

      <template #actions="{ showForm }">
        <gl-button
          size="small"
          :disabled="!canAdd || isSaving"
          data-testid="add-client-button"
          @click="showAddForm(showForm)"
        >
          {{ $options.i18n.addClient }}
        </gl-button>
      </template>

      <template #form="{ hideForm }">
        <client-form
          :key="editedIndex"
          :client="editedClient"
          :other-clients="otherClients"
          :is-saving="isSaving"
          @submit="submitClient($event, hideForm)"
          @cancel="cancelForm(hideForm)"
        />
      </template>

      <template v-if="clients.length === 0" #empty>
        {{ $options.i18n.empty }}
      </template>

      <template #default="{ showForm }">
        <gl-table
          :items="clients"
          :fields="$options.fields"
          stacked="md"
          :aria-label="$options.i18n.title"
        >
          <template #cell(actions)="{ index }">
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="pencil"
              :disabled="isSaving"
              :title="$options.i18n.editClient"
              :aria-label="$options.i18n.editClient"
              data-testid="edit-client-button"
              @click="showEditForm(index, showForm)"
            />
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="remove"
              :disabled="isSaving"
              :title="$options.i18n.deleteClient"
              :aria-label="$options.i18n.deleteClient"
              data-testid="delete-client-button"
              @click="confirmDelete(index)"
            />
          </template>
        </gl-table>
      </template>
    </crud-component>

    <gl-modal
      ref="deleteModal"
      modal-id="code-dropdown-client-delete-modal"
      :title="deleteModalTitle"
      :action-primary="$options.deleteModalActions.primary"
      :action-cancel="$options.deleteModalActions.cancel"
      data-testid="delete-client-modal"
      @primary="deleteClient"
    >
      {{ deleteModalBody }}
    </gl-modal>
  </div>
</template>
