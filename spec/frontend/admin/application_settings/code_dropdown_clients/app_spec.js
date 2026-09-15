import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { GlAlert, GlModal, GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import App from '~/admin/application_settings/code_dropdown_clients/app.vue';
import ClientForm from '~/admin/application_settings/code_dropdown_clients/client_form.vue';
import { MAX_CLIENTS } from '~/admin/application_settings/code_dropdown_clients/constants';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/lib/logger');

const SETTINGS_URL = /\/api\/.*\/application\/settings/;

describe('CodeDropdownClientsApp', () => {
  let wrapper;
  let mock;

  const vscodium = {
    name: 'VSCodium',
    ssh_url_template: 'vscodium://vscode.git/clone?url={url}',
    http_url_template: 'vscodium://vscode.git/clone?url={url}',
  };
  const tower = { ...vscodium, name: 'Tower' };

  const showModal = jest.fn();

  const createComponent = ({ initialClients = [] } = {}) => {
    wrapper = mountExtended(App, {
      propsData: { initialClients },
      // GlModal does not render its slot until it is shown, so stub it to keep the
      // confirmation copy assertable.
      stubs: { GlModal: stubComponent(GlModal, { methods: { show: showModal } }) },
    });
  };

  const findCrud = () => wrapper.findComponent(CrudComponent);
  const findTable = () => wrapper.findComponent(GlTable);
  const findForm = () => wrapper.findComponent(ClientForm);
  const findModal = () => wrapper.findComponent(GlModal);
  const findAddButton = () => wrapper.findComponentByTestId('add-client-button');
  const findEditButtons = () => wrapper.findAllComponentsByTestId('edit-client-button');
  const findDeleteButtons = () => wrapper.findAllComponentsByTestId('delete-client-button');
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findValidationAlert = () => wrapper.findByTestId('validation-alert');

  const lastRequestBody = () => JSON.parse(mock.history.put[0].data);

  const openAddForm = async () => {
    findAddButton().vm.$emit('click');
    await nextTick();
  };

  const submitForm = async (entry = vscodium) => {
    findForm().vm.$emit('submit', entry);
    await waitForPromises();
  };

  beforeEach(() => {
    showModal.mockClear();
    mock = new MockAdapter(axios);
    mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_OK, {});
  });

  afterEach(() => {
    mock.restore();
  });

  describe('rendering', () => {
    it('describes the setting without linking to the schemes documentation', () => {
      createComponent();

      const description = wrapper.findByTestId('crud-description');

      expect(description.text()).toContain('add only clients you trust');
      expect(description.find('a').exists()).toBe(false);
    });

    it('renders the empty state and no table', () => {
      createComponent();

      expect(wrapper.findByTestId('crud-empty').text()).toBe('No clients have been added.');
      expect(findTable().exists()).toBe(false);
    });

    it('aligns table cells to match other CRUD tables', () => {
      createComponent({ initialClients: [vscodium] });

      const cellClasses = wrapper.findAll('tbody td').wrappers.map((td) => td.classes());

      cellClasses.forEach((classes) => {
        expect(classes).toEqual(expect.arrayContaining(['!gl-align-middle', '!gl-py-3']));
      });
    });

    it('lists each client by name with a count', () => {
      createComponent({ initialClients: [vscodium] });

      expect(wrapper.findAll('tbody tr')).toHaveLength(1);
      expect(wrapper.text()).toContain('VSCodium');
      expect(findCrud().props('count')).toBe(1);
    });

    it('does not show the form until "Add client" is clicked', async () => {
      createComponent();
      expect(findForm().exists()).toBe(false);

      await openAddForm();

      expect(findForm().exists()).toBe(true);
      expect(findForm().props('client')).toBe(null);
    });
  });

  describe('adding a client', () => {
    beforeEach(async () => {
      createComponent();
      await openAddForm();
    });

    it('persists the whole list and shows a toast', async () => {
      await submitForm();

      expect(mock.history.put).toHaveLength(1);
      expect(lastRequestBody()).toEqual({ code_dropdown_custom_clients: [vscodium] });
      expect(toast).toHaveBeenCalledWith('Code dropdown clients updated.');
    });

    // The schema gives every template key a minimum length, so a blank one has to be
    // left out rather than sent as an empty string.
    it('omits a template that was left blank', async () => {
      await submitForm({
        name: 'SSH only',
        ssh_url_template: 'vscodium://clone?url={url}',
        http_url_template: '',
      });

      expect(lastRequestBody()).toEqual({
        code_dropdown_custom_clients: [
          { name: 'SSH only', ssh_url_template: 'vscodium://clone?url={url}' },
        ],
      });
    });

    it('omits an SSH template that was left blank', async () => {
      await submitForm({
        name: 'HTTPS only',
        ssh_url_template: '',
        http_url_template: 'vscodium://clone?url={url}',
      });

      expect(lastRequestBody()).toEqual({
        code_dropdown_custom_clients: [
          { name: 'HTTPS only', http_url_template: 'vscodium://clone?url={url}' },
        ],
      });
    });

    it('adds the row and closes the form once the request succeeds', async () => {
      await submitForm();

      expect(wrapper.text()).toContain('VSCodium');
      expect(findForm().exists()).toBe(false);
    });

    it('does not persist on cancel', async () => {
      findForm().vm.$emit('cancel');
      await waitForPromises();

      expect(mock.history.put).toHaveLength(0);
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('when the request fails', () => {
    beforeEach(async () => {
      createComponent();
      await openAddForm();
    });

    it('keeps the entry out of the list and leaves the form open', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, { message: 'Nope' });

      await submitForm();

      expect(wrapper.text()).not.toContain('VSCodium');
      expect(findForm().exists()).toBe(true);
      expect(toast).not.toHaveBeenCalled();
    });

    it('shows a validation alert listing the server-side messages', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, {
        message: { code_dropdown_custom_clients: ['entry 1 SSH URL template: is not allowed'] },
      });

      await submitForm();

      expect(findValidationAlert().text()).toContain('entry 1 SSH URL template: is not allowed');
      expect(findErrorAlert().exists()).toBe(false);
    });

    it('falls back to a generic message when the server sends none', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, {});

      await submitForm();

      expect(findErrorAlert().text()).toBe('An unknown error occurred. Please try again.');
    });

    it('shows a parameter validation error from the API', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, {
        error: 'code_dropdown_custom_clients[0][name] is missing',
      });

      await submitForm();

      expect(findErrorAlert().text()).toBe('code_dropdown_custom_clients[0][name] is missing');
    });

    it('shows a plain server message as-is', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, { message: 'Nope' });

      await submitForm();

      expect(findErrorAlert().text()).toBe('Nope');
    });
  });

  describe('editing a client', () => {
    beforeEach(async () => {
      createComponent({ initialClients: [vscodium] });
      findEditButtons().at(0).vm.$emit('click');
      await nextTick();
    });

    it('opens the form prefilled and excludes the edited entry from the duplicate check', () => {
      expect(findForm().props('client')).toEqual(vscodium);
      expect(findForm().props('otherClients')).toEqual([]);
    });

    it('replaces the client in place instead of appending', async () => {
      await submitForm({ ...vscodium, name: 'Fork' });

      expect(lastRequestBody()).toEqual({
        code_dropdown_custom_clients: [{ ...vscodium, name: 'Fork' }],
      });
    });
  });

  describe('deleting a client', () => {
    beforeEach(async () => {
      createComponent({ initialClients: [vscodium, tower] });
      findDeleteButtons().at(0).vm.$emit('click');
      await nextTick();
    });

    it('asks for confirmation naming the client, and persists nothing yet', () => {
      expect(showModal).toHaveBeenCalled();
      expect(findModal().text()).toContain('You are about to delete the VSCodium client.');
      expect(findModal().props('title')).toBe('Delete code dropdown client?');
      expect(mock.history.put).toHaveLength(0);
    });

    it('shows special characters in the client name unescaped', async () => {
      createComponent({ initialClients: [{ ...vscodium, name: 'Tom & Jerry' }] });
      findDeleteButtons().at(0).vm.$emit('click');
      await nextTick();

      expect(findModal().text()).toContain('You are about to delete the Tom & Jerry client.');
    });

    it('removes only the selected client once confirmed', async () => {
      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(lastRequestBody()).toEqual({ code_dropdown_custom_clients: [tower] });
      expect(wrapper.text()).not.toContain('VSCodium');
      expect(wrapper.text()).toContain('Tower');
    });

    it('keeps the client when the request fails', async () => {
      mock.onPut(SETTINGS_URL).reply(HTTP_STATUS_BAD_REQUEST, { message: 'Nope' });

      findModal().vm.$emit('primary');
      await waitForPromises();

      expect(wrapper.text()).toContain('VSCodium');
      expect(findErrorAlert().text()).toBe('Nope');
    });
  });

  describe('client limit', () => {
    it(`disables "Add client" at ${MAX_CLIENTS} clients`, () => {
      createComponent({
        initialClients: Array.from({ length: MAX_CLIENTS }, (_, i) => ({
          ...vscodium,
          name: `Client ${i}`,
        })),
      });

      expect(findAddButton().props('disabled')).toBe(true);
    });

    it('enables "Add client" below the limit', () => {
      createComponent({ initialClients: [vscodium] });

      expect(findAddButton().props('disabled')).toBe(false);
    });
  });

  describe('alerts', () => {
    it('renders no alert before anything fails', () => {
      createComponent();

      expect(wrapper.findAllComponents(GlAlert)).toHaveLength(0);
    });
  });
});
