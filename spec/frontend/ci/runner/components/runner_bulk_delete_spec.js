import Vue from 'vue';
import { makeVar } from '@apollo/client/core';
import { GlModal, GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerBulkDelete from '~/ci/runner/components/runner_bulk_delete.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import BulkRunnerDeleteMutation from '~/ci/runner/graphql/list/bulk_runner_delete.mutation.graphql';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';
import waitForPromises from 'helpers/wait_for_promises';
import { allRunnersData } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('RunnerBulkDelete', () => {
  let wrapper;
  let apolloCache;
  let mockState;
  let mockCheckedRunnerIds;

  const findBanner = () => wrapper.findByTestId('runner-bulk-delete-banner');
  const findClearBtn = () => wrapper.findByTestId('clear-selection');
  const findDeleteBtn = () => wrapper.findByTestId('delete-selected');
  const findModal = () => wrapper.findComponent(GlModal);

  const mockRunners = allRunnersData.data.runners.nodes;
  const mockId1 = allRunnersData.data.runners.nodes[0].id;
  const mockId2 = allRunnersData.data.runners.nodes[1].id;

  const bulkRunnerDeleteHandler = jest.fn();

  const createComponent = ({ stubs } = {}) => {
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
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlSprintf,
        GlModal,
        ...stubs,
      },
    });

    apolloCache = apolloProvider.defaultClient.cache;
    jest.spyOn(apolloCache, 'evict');
    jest.spyOn(apolloCache, 'gc');
  };

  beforeEach(() => {
    mockState = createLocalState();
    mockCheckedRunnerIds = makeVar([]);

    jest
      .spyOn(mockState.cacheConfig.typePolicies.Query.fields, 'checkedRunnerIds')
      .mockImplementation(() => mockCheckedRunnerIds());
  });

  afterEach(() => {
    bulkRunnerDeleteHandler.mockReset();
  });

  describe('When no runners are checked', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('shows no contents', () => {
      expect(findBanner().exists()).toBe(false);
    });
  });

  describe.each`
    count | ids                   | text
    ${1}  | ${[mockId1]}          | ${'1 runner'}
    ${2}  | ${[mockId1, mockId2]} | ${'2 runners'}
  `('When $count runner(s) are checked', ({ ids, text }) => {
    beforeEach(() => {
      mockCheckedRunnerIds(ids);

      createComponent();

      jest.spyOn(mockState.localMutations, 'clearChecked').mockImplementation(() => {});
    });

    it(`shows "${text}"`, () => {
      expect(findBanner().text()).toContain(text);
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

    const confirmDeletion = () => {
      evt = {
        preventDefault: jest.fn(),
      };
      findModal().vm.$emit('primary', evt);
    };

    beforeEach(() => {
      mockCheckedRunnerIds([mockId1, mockId2]);
      mockHideModal = jest.fn();

      createComponent({
        stubs: {
          GlModal: stubComponent(GlModal, { methods: { hide: mockHideModal } }),
        },
      });

      jest.spyOn(mockState.localMutations, 'clearChecked').mockImplementation(() => {});
    });

    describe('when deletion is confirmed', () => {
      beforeEach(() => {
        confirmDeletion();
      });

      it('has loading state', () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
        expect(findModal().props('actionCancel').attributes.loading).toBe(true);
      });

      it('modal is not prevented from closing', () => {
        expect(evt.preventDefault).toHaveBeenCalledTimes(1);
      });

      it('mutation is called', () => {
        expect(bulkRunnerDeleteHandler).toHaveBeenCalledWith({
          input: { ids: mockCheckedRunnerIds() },
        });
      });
    });

    describe('when deletion is successful', () => {
      let deletedIds;

      beforeEach(async () => {
        deletedIds = mockCheckedRunnerIds();
        bulkRunnerDeleteHandler.mockResolvedValue({
          data: {
            bulkRunnerDelete: { deletedIds, errors: [] },
          },
        });
        confirmDeletion();
        mockCheckedRunnerIds([]);
        await waitForPromises();
      });

      it('removes loading state', () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        expect(findModal().props('actionCancel').attributes.loading).toBe(false);
      });

      it('user interface is updated', () => {
        const { evict, gc } = apolloCache;

        expect(evict).toHaveBeenCalledTimes(deletedIds.length);
        expect(evict).toHaveBeenCalledWith({
          id: expect.stringContaining(deletedIds[0]),
        });
        expect(evict).toHaveBeenCalledWith({
          id: expect.stringContaining(deletedIds[1]),
        });

        expect(gc).toHaveBeenCalledTimes(1);
      });

      it('emits deletion confirmation', () => {
        expect(wrapper.emitted('deleted')).toEqual([
          [{ message: expect.stringContaining(`${deletedIds.length}`) }],
        ]);
      });

      it('modal is hidden', () => {
        expect(mockHideModal).toHaveBeenCalledTimes(1);
      });
    });

    describe('when deletion fails partially', () => {
      beforeEach(async () => {
        bulkRunnerDeleteHandler.mockResolvedValue({
          data: {
            bulkRunnerDelete: {
              deletedIds: [mockId1], // only one runner could be deleted
              errors: ['Can only delete up to 1 runners per call. Ignored 1 runner(s).'],
            },
          },
        });

        confirmDeletion();
        await waitForPromises();
      });

      it('removes loading state', () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        expect(findModal().props('actionCancel').attributes.loading).toBe(false);
      });

      it('user interface is partially updated', () => {
        const { evict, gc } = apolloCache;

        expect(evict).toHaveBeenCalledTimes(1);
        expect(evict).toHaveBeenCalledWith({
          id: expect.stringContaining(mockId1),
        });

        expect(gc).toHaveBeenCalledTimes(1);
      });

      it('emits deletion confirmation', () => {
        expect(wrapper.emitted('deleted')).toEqual([[{ message: expect.stringContaining('1') }]]);
      });

      it('alert is called', () => {
        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.any(String),
          captureError: true,
          error: expect.any(Error),
        });
      });

      it('modal is hidden', () => {
        expect(mockHideModal).toHaveBeenCalledTimes(1);
      });
    });

    describe('when deletion fails', () => {
      beforeEach(async () => {
        bulkRunnerDeleteHandler.mockRejectedValue(new Error('error!'));

        confirmDeletion();
        await waitForPromises();
      });

      it('resolves loading state', () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        expect(findModal().props('actionCancel').attributes.loading).toBe(false);
      });

      it('user interface is not updated', () => {
        const { evict, gc } = apolloCache;

        expect(evict).not.toHaveBeenCalled();
        expect(gc).not.toHaveBeenCalled();
        expect(mockState.localMutations.clearChecked).not.toHaveBeenCalled();
      });

      it('does not emit deletion confirmation', () => {
        expect(wrapper.emitted('deleted')).toBeUndefined();
      });

      it('alert is called', () => {
        expect(createAlert).toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.any(String),
          captureError: true,
          error: expect.any(Error),
        });
      });

      it('modal is hidden', () => {
        expect(mockHideModal).toHaveBeenCalledTimes(1);
      });
    });
  });
});
