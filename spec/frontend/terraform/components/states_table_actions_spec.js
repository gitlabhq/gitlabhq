import { GlDropdown } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import VueApollo from 'vue-apollo';
import StateActions from '~/terraform/components/states_table_actions.vue';
import lockStateMutation from '~/terraform/graphql/mutations/lock_state.mutation.graphql';
import unlockStateMutation from '~/terraform/graphql/mutations/unlock_state.mutation.graphql';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('StatesTableActions', () => {
  let lockResponse;
  let unlockResponse;
  let wrapper;

  const defaultProps = {
    state: {
      id: 'gid/1',
      name: 'state-1',
      latestVersion: { downloadPath: '/path' },
      lockedAt: '2020-10-13T00:00:00Z',
    },
  };

  const createMockApolloProvider = () => {
    lockResponse = jest.fn().mockResolvedValue({ data: { terraformStateLock: { errors: [] } } });

    unlockResponse = jest
      .fn()
      .mockResolvedValue({ data: { terraformStateUnlock: { errors: [] } } });

    return createMockApollo([
      [lockStateMutation, lockResponse],
      [unlockStateMutation, unlockResponse],
    ]);
  };

  const createComponent = (propsData = defaultProps) => {
    const apolloProvider = createMockApolloProvider();

    wrapper = shallowMount(StateActions, {
      apolloProvider,
      localVue,
      propsData,
      stubs: { GlDropdown },
    });

    return wrapper.vm.$nextTick();
  };

  const findLockBtn = () => wrapper.find('[data-testid="terraform-state-lock"]');
  const findUnlockBtn = () => wrapper.find('[data-testid="terraform-state-unlock"]');
  const findDownloadBtn = () => wrapper.find('[data-testid="terraform-state-download"]');

  beforeEach(() => {
    return createComponent();
  });

  afterEach(() => {
    lockResponse = null;
    unlockResponse = null;
    wrapper.destroy();
  });

  describe('download button', () => {
    it('displays a download button', () => {
      expect(findDownloadBtn().text()).toBe('Download JSON');
    });

    describe('when state does not have a latestVersion', () => {
      beforeEach(() => {
        return createComponent({
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
        return wrapper.vm.$nextTick();
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
        return wrapper.vm.$nextTick();
      });

      it('calls the lock mutation', () => {
        expect(lockResponse).toHaveBeenCalledWith({
          stateID: unlockedProps.state.id,
        });
      });
    });
  });
});
