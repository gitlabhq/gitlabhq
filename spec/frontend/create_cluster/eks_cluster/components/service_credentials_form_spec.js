import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import ServiceCredentialsForm from '~/create_cluster/eks_cluster/components/service_credentials_form.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

import eksClusterState from '~/create_cluster/eks_cluster/store/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ServiceCredentialsForm', () => {
  let vm;
  let state;
  let createRoleAction;
  const accountId = 'accountId';
  const externalId = 'externalId';

  beforeEach(() => {
    state = Object.assign(eksClusterState(), {
      accountId,
      externalId,
    });
    createRoleAction = jest.fn();

    const store = new Vuex.Store({
      state,
      actions: {
        createRole: createRoleAction,
      },
    });
    vm = shallowMount(ServiceCredentialsForm, {
      propsData: {
        accountAndExternalIdsHelpPath: '',
        createRoleArnHelpPath: '',
        externalLinkIcon: '',
      },
      localVue,
      store,
    });
  });
  afterEach(() => vm.destroy());

  const findAccountIdInput = () => vm.find('#gitlab-account-id');
  const findCopyAccountIdButton = () => vm.find('.js-copy-account-id-button');
  const findExternalIdInput = () => vm.find('#eks-external-id');
  const findCopyExternalIdButton = () => vm.find('.js-copy-external-id-button');
  const findInvalidCredentials = () => vm.find('.js-invalid-credentials');
  const findSubmitButton = () => vm.find(LoadingButton);
  const findForm = () => vm.find('form[name="service-credentials-form"]');

  it('displays provided account id', () => {
    expect(findAccountIdInput().attributes('value')).toBe(accountId);
  });

  it('allows to copy account id', () => {
    expect(findCopyAccountIdButton().props('text')).toBe(accountId);
  });

  it('displays provided external id', () => {
    expect(findExternalIdInput().attributes('value')).toBe(externalId);
  });

  it('allows to copy external id', () => {
    expect(findCopyExternalIdButton().props('text')).toBe(externalId);
  });

  it('disables submit button when role ARN is not provided', () => {
    expect(findSubmitButton().attributes('disabled')).toBeTruthy();
  });

  it('enables submit button when role ARN is not provided', () => {
    vm.setData({ roleArn: '123' });

    expect(findSubmitButton().attributes('disabled')).toBeFalsy();
  });

  it('dispatches createRole action when form is submitted', () => {
    findForm().trigger('submit');

    expect(createRoleAction).toHaveBeenCalled();
  });

  describe('when is creating role', () => {
    beforeEach(() => {
      vm.setData({ roleArn: '123' }); // set role ARN to enable button

      state.isCreatingRole = true;
    });

    it('disables submit button', () => {
      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('sets submit button as loading', () => {
      expect(findSubmitButton().props('loading')).toBe(true);
    });

    it('displays Authenticating label on submit button', () => {
      expect(findSubmitButton().props('label')).toBe('Authenticating');
    });
  });

  describe('when role can’t be created', () => {
    beforeEach(() => {
      state.createRoleError = 'Invalid credentials';
    });

    it('displays invalid role warning banner', () => {
      expect(findInvalidCredentials().exists()).toBe(true);
    });

    it('displays invalid role error message', () => {
      expect(findInvalidCredentials().text()).toContain(state.createRoleError);
    });
  });
});
