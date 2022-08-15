import Vue from 'vue';
import { GlModal, GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/flash';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import RunnerBulkDelete from '~/runner/components/runner_bulk_delete.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import BulkRunnerDeleteMutation from '~/runner/graphql/list/bulk_runner_delete.mutation.graphql';
import { createLocalState } from '~/runner/graphql/list/local_state';
import waitForPromises from 'helpers/wait_for_promises';
import { allRunnersData } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');

describe('RunnerBulkDelete', () => {
  let wrapper;
  let apolloCache;
  let mockState;
  let mockCheckedRunnerIds;

  const findClearBtn = () => wrapper.findByText(s__('Runners|Clear selection'));
  const findDeleteBtn = () => wrapper.findByText(s__('Runners|Delete selected'));
  const findModal = () => wrapper.findComponent(GlModal);

  const mockRunners = allRunnersData.data.runners.nodes;
  const mockId1 = allRunnersData.data.runners.nodes[0].id;
  const mockId2 = allRunnersData.data.runners.nodes[1].id;

  const bulkRunnerDeleteHandler = jest.fn();

  const createComponent = () => {
    const { cacheConfig, localMutations } = mockState;
    const apolloProvider = createMockApollo(
      [[BulkRunnerDeleteMutation, bulkRunnerDeleteHandler]],
      undefined,
      cacheConfig,
    );

    wrapper = shallowMountExtended(RunnerBulkDelete, {
      apolloProvider,
      provide: {
        localMutations,
      },
      propsData: {
        runners: mockRunners,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
      stubs: {
        GlSprintf,
        GlModal,
      },
    });

    apolloCache = apolloProvider.defaultClient.cache;
    jest.spyOn(apolloCache, 'evict');
    jest.spyOn(apolloCache, 'gc');
  };

  beforeEach(() => {
    mockState = createLocalState();

    jest
      .spyOn(mockState.cacheConfig.typePolicies.Query.fields, 'checkedRunnerIds')
      .mockImplementation(() => mockCheckedRunnerIds);
  });

  afterEach(() => {
    bulkRunnerDeleteHandler.mockReset();
    wrapper.destroy();
  });

  describe('When no runners are checked', () => {
    beforeEach(async () => {
      mockCheckedRunnerIds = [];

      createComponent();

      await waitForPromises();
    });

    it('shows no contents', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe.each`
    count | ids                   | text
    ${1}  | ${[mockId1]}          | ${'1 runner'}
    ${2}  | ${[mockId1, mockId2]} | ${'2 runners'}
  `('When $count runner(s) are checked', ({ ids, text }) => {
    beforeEach(() => {
      mockCheckedRunnerIds = ids;

      createComponent();

      jest.spyOn(mockState.localMutations, 'clearChecked').mockImplementation(() => {});
    });

    it(`shows "${text}"`, () => {
      expect(wrapper.text()).toContain(text);
    });

    it('clears selection', () => {
      expect(mockState.localMutations.clearChecked).toHaveBeenCalledTimes(0);

      findClearBtn().vm.$emit('click');

      expect(mockState.localMutations.clearChecked).toHaveBeenCalledTimes(1);
    });

    it('shows confirmation modal', () => {
      const modalId = getBinding(findDeleteBtn().element, 'gl-modal');

      expect(findModal().props('modal-id')).toBe(modalId);
      expect(findModal().text()).toContain(text);
    });
  });

  describe('when runners are deleted', () => {
    let evt;
    let mockHideModal;

    beforeEach(() => {
      mockCheckedRunnerIds = [mockId1, mockId2];

      createComponent();

      jest.spyOn(mockState.localMutations, 'clearChecked').mockImplementation(() => {});
      mockHideModal = jest.spyOn(findModal().vm, 'hide');
    });

    describe('when deletion is successful', () => {
      beforeEach(() => {
        bulkRunnerDeleteHandler.mockResolvedValue({
          data: {
            bulkRunnerDelete: { deletedIds: mockCheckedRunnerIds, errors: [] },
          },
        });

        evt = {
          preventDefault: jest.fn(),
        };
        findModal().vm.$emit('primary', evt);
      });

      it('has loading state', async () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
        expect(findModal().props('actionCancel').attributes.loading).toBe(true);

        await waitForPromises();

        expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        expect(findModal().props('actionCancel').attributes.loading).toBe(false);
      });

      it('modal is not prevented from closing', () => {
        expect(evt.preventDefault).toHaveBeenCalledTimes(1);
      });

      it('mutation is called', async () => {
        expect(bulkRunnerDeleteHandler).toHaveBeenCalledWith({
          input: { ids: mockCheckedRunnerIds },
        });
      });

      it('user interface is updated', async () => {
        const { evict, gc } = apolloCache;

        expect(evict).toHaveBeenCalledTimes(mockCheckedRunnerIds.length);
        expect(evict).toHaveBeenCalledWith({
          id: expect.stringContaining(mockCheckedRunnerIds[0]),
        });
        expect(evict).toHaveBeenCalledWith({
          id: expect.stringContaining(mockCheckedRunnerIds[1]),
        });

        expect(gc).toHaveBeenCalledTimes(1);
      });

      it('modal is hidden', () => {
        expect(mockHideModal).toHaveBeenCalledTimes(1);
      });
    });

    describe('when deletion fails', () => {
      beforeEach(() => {
        bulkRunnerDeleteHandler.mockRejectedValue(new Error('error!'));

        evt = {
          preventDefault: jest.fn(),
        };
        findModal().vm.$emit('primary', evt);
      });

      it('has loading state', async () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
        expect(findModal().props('actionCancel').attributes.loading).toBe(true);

        await waitForPromises();

        expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        expect(findModal().props('actionCancel').attributes.loading).toBe(false);
      });

      it('modal is not prevented from closing', () => {
        expect(evt.preventDefault).toHaveBeenCalledTimes(1);
      });

      it('mutation is called', () => {
        expect(bulkRunnerDeleteHandler).toHaveBeenCalledWith({
          input: { ids: mockCheckedRunnerIds },
        });
      });

      it('user interface is not updated', async () => {
        await waitForPromises();

        const { evict, gc } = apolloCache;

        expect(evict).not.toHaveBeenCalled();
        expect(gc).not.toHaveBeenCalled();
        expect(mockState.localMutations.clearChecked).not.toHaveBeenCalled();
      });

      it('alert is called', async () => {
        await waitForPromises();

        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.any(String),
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });
});
