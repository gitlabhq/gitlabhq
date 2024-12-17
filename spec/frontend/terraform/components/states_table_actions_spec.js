import { GlDropdown, GlModal, GlSprintf, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import InitCommandModal from '~/terraform/components/init_command_modal.vue';
import StateActions from '~/terraform/components/states_table_actions.vue';
import lockStateMutation from '~/terraform/graphql/mutations/lock_state.mutation.graphql';
import removeStateMutation from '~/terraform/graphql/mutations/remove_state.mutation.graphql';
import unlockStateMutation from '~/terraform/graphql/mutations/unlock_state.mutation.graphql';
import getStatesQuery from '~/terraform/graphql/queries/get_states.query.graphql';
import { getStatesResponse } from './mock_data';

Vue.use(VueApollo);

describe('StatesTableActions', () => {
  let lockResponse;
  let removeResponse;
  let toast;
  let unlockResponse;
  let updateStateResponse;
  let wrapper;

  const defaultProps = {
    state: {
      id: 'gid/1',
      name: 'state-1',
      latestVersion: { downloadPath: '/path' },
      lockedAt: '2020-10-13T00:00:00Z',
    },
    terraformAdmin: true,
  };

  const createMockApolloProvider = () => {
    lockResponse = jest
      .fn()
      .mockResolvedValue({ data: { terraformStateLock: { errors: ['There was an error'] } } });

    removeResponse = jest
      .fn()
      .mockResolvedValue({ data: { terraformStateDelete: { errors: [] } } });

    unlockResponse = jest
      .fn()
      .mockResolvedValue({ data: { terraformStateUnlock: { errors: [] } } });

    updateStateResponse = jest.fn().mockResolvedValue({});

    return createMockApollo(
      [
        [lockStateMutation, lockResponse],
        [removeStateMutation, removeResponse],
        [unlockStateMutation, unlockResponse],
        [getStatesQuery, jest.fn().mockResolvedValue(getStatesResponse)],
      ],
      {
        Mutation: {
          addDataToTerraformState: updateStateResponse,
        },
      },
    );
  };

  const createComponent = async (propsData = defaultProps) => {
    const apolloProvider = createMockApolloProvider();

    toast = jest.fn();

    wrapper = shallowMount(StateActions, {
      apolloProvider,
      propsData,
      provide: { projectPath: 'path/to/project' },
      mocks: { $toast: { show: toast } },
      stubs: { GlDropdown, GlModal, GlSprintf },
    });

    await nextTick();
  };

  const findActionsDropdown = () => wrapper.findComponent(GlDropdown);
  const findCopyBtn = () => wrapper.find('[data-testid="terraform-state-copy-init-command"]');
  const findCopyModal = () => wrapper.findComponent(InitCommandModal);
  const findLockBtn = () => wrapper.find('[data-testid="terraform-state-lock"]');
  const findUnlockBtn = () => wrapper.find('[data-testid="terraform-state-unlock"]');
  const findDownloadBtn = () => wrapper.find('[data-testid="terraform-state-download"]');
  const findRemoveBtn = () => wrapper.find('[data-testid="terraform-state-remove"]');
  const findRemoveModal = () => wrapper.findComponent(GlModal);
  const findFormInput = () => wrapper.findComponent(GlFormInput);

  beforeEach(() => {
    return createComponent();
  });

  afterEach(() => {
    lockResponse = null;
    removeResponse = null;
    toast = null;
    unlockResponse = null;
    updateStateResponse = null;
  });

  describe('when the state is loading', () => {
    describe('when lock/unlock is processing', () => {
      beforeEach(() => {
        return createComponent({
          ...defaultProps,
          state: {
            ...defaultProps.state,
            loadingLock: true,
          },
        });
      });

      it('disables the actions dropdown', () => {
        expect(findActionsDropdown().props('disabled')).toBe(true);
      });
    });

    describe('when remove is processing', () => {
      beforeEach(() => {
        return createComponent({
          ...defaultProps,
          state: {
            ...defaultProps.state,
            loadingRemove: true,
          },
        });
      });

      it('disables the actions dropdown', () => {
        expect(findActionsDropdown().props('disabled')).toBe(true);
      });
    });
  });

  describe('copy command button', () => {
    it('displays a copy init command button', () => {
      expect(findCopyBtn().text()).toBe('Copy Terraform init command');
    });

    describe('when clicking the copy init command button', () => {
      beforeEach(() => {
        findCopyBtn().vm.$emit('click');

        return waitForPromises();
      });

      it('opens the modal', () => {
        expect(findCopyModal().exists()).toBe(true);
        expect(findCopyModal().isVisible()).toBe(true);
      });
    });
  });

  describe('download button', () => {
    it('displays a download button', () => {
      expect(findDownloadBtn().text()).toBe('Download JSON');
    });

    describe('when state does not have a latestVersion', () => {
      beforeEach(() => {
        return createComponent({
          ...defaultProps,
          state: {
            id: 'gid/1',
            name: 'state-1',
            latestVersion: null,
          },
        });
      });

      it('does not display a download button', () => {
        expect(findDownloadBtn().exists()).toBe(false);
      });
    });
  });

  describe('unlock button', () => {
    it('displays an unlock button', () => {
      expect(findUnlockBtn().text()).toBe('Unlock');
      expect(findLockBtn().exists()).toBe(false);
    });

    describe('when clicking the unlock button', () => {
      beforeEach(() => {
        findUnlockBtn().vm.$emit('click');

        return waitForPromises();
      });

      it('calls the unlock mutation', () => {
        expect(unlockResponse).toHaveBeenCalledWith({
          stateID: defaultProps.state.id,
        });
      });
    });
  });

  describe('lock button', () => {
    const unlockedProps = {
      ...defaultProps,
      state: {
        id: 'gid/2',
        name: 'state-2',
        latestVersion: null,
        lockedAt: null,
      },
    };

    beforeEach(() => {
      return createComponent(unlockedProps);
    });

    it('displays a lock button', () => {
      expect(findLockBtn().text()).toBe('Lock');
      expect(findUnlockBtn().exists()).toBe(false);
    });

    describe('when clicking the lock button', () => {
      beforeEach(() => {
        findLockBtn().vm.$emit('click');

        return waitForPromises();
      });

      it('calls the lock mutation', () => {
        expect(lockResponse).toHaveBeenCalledWith({
          stateID: unlockedProps.state.id,
        });
      });

      it('calls mutations to set loading and errors', () => {
        // loading update
        expect(updateStateResponse).toHaveBeenNthCalledWith(
          1,
          {},
          {
            terraformState: {
              ...unlockedProps.state,
              _showDetails: false,
              errorMessages: [],
              loadingLock: true,
              loadingRemove: false,
            },
          },
          // Apollo fields
          expect.any(Object),
          expect.any(Object),
        );

        // final update
        expect(updateStateResponse).toHaveBeenNthCalledWith(
          2,
          {},
          {
            terraformState: {
              ...unlockedProps.state,
              _showDetails: true,
              errorMessages: ['There was an error'],
              loadingLock: false,
              loadingRemove: false,
            },
          },
          // Apollo fields
          expect.any(Object),
          expect.any(Object),
        );
      });
    });
  });

  describe('remove button', () => {
    it('displays a remove button', () => {
      expect(findRemoveBtn().text()).toBe(StateActions.i18n.remove);
    });

    describe('when clicking the remove button', () => {
      beforeEach(() => {
        findRemoveBtn().vm.$emit('click');
        return waitForPromises();
      });

      it('displays a remove modal', () => {
        expect(findRemoveModal().text()).toContain(
          `You are about to remove the state file ${defaultProps.state.name}`,
        );
      });

      describe('when submitting the remove modal', () => {
        describe('when state name is missing', () => {
          beforeEach(() => {
            findRemoveModal().vm.$emit('ok');
            return waitForPromises();
          });

          it('does not call the remove mutation', () => {
            expect(removeResponse).not.toHaveBeenCalledWith();
          });
        });

        describe('when state name is present', () => {
          beforeEach(async () => {
            await findFormInput().vm.$emit('input', defaultProps.state.name);

            findRemoveModal().vm.$emit('ok');

            await waitForPromises();
          });

          it('calls the remove mutation', () => {
            expect(removeResponse).toHaveBeenCalledWith({ stateID: defaultProps.state.id });
          });

          it('calls the toast action', () => {
            expect(toast).toHaveBeenCalledWith(`${defaultProps.state.name} successfully removed`);
          });

          it('calls mutations to set loading and errors', () => {
            // loading update
            expect(updateStateResponse).toHaveBeenNthCalledWith(
              1,
              {},
              {
                terraformState: {
                  ...defaultProps.state,
                  _showDetails: false,
                  errorMessages: [],
                  loadingLock: false,
                  loadingRemove: true,
                },
              },
              // Apollo fields
              expect.any(Object),
              expect.any(Object),
            );

            // final update
            expect(updateStateResponse).toHaveBeenNthCalledWith(
              2,
              {},
              {
                terraformState: {
                  ...defaultProps.state,
                  _showDetails: false,
                  errorMessages: [],
                  loadingLock: false,
                  loadingRemove: false,
                },
              },
              // Apollo fields
              expect.any(Object),
              expect.any(Object),
            );
          });
        });
      });
    });
  });

  describe('when the user has an administrator role', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('displays all available action buttons', () => {
      expect(findCopyBtn().exists()).toBe(true);
      expect(findDownloadBtn().exists()).toBe(true);
      expect(findUnlockBtn().exists()).toBe(true);
      expect(findRemoveBtn().exists()).toBe(true);
    });
  });

  describe('when the user does not have an administrator role', () => {
    beforeEach(() => {
      return createComponent({ ...defaultProps, terraformAdmin: false });
    });

    it('displays "copy init command" and "download" action buttons', () => {
      expect(findCopyBtn().exists()).toBe(true);
      expect(findDownloadBtn().exists()).toBe(true);
      expect(findUnlockBtn().exists()).toBe(false);
      expect(findRemoveBtn().exists()).toBe(false);
    });
  });
});
