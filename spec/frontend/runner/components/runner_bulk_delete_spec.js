import Vue from 'vue';
import { GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import RunnerBulkDelete from '~/runner/components/runner_bulk_delete.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createLocalState } from '~/runner/graphql/list/local_state';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('RunnerBulkDelete', () => {
  let wrapper;
  let mockState;
  let mockCheckedRunnerIds;

  const findClearBtn = () => wrapper.findByTestId('clear-btn');
  const findDeleteBtn = () => wrapper.findByTestId('delete-btn');

  const createComponent = () => {
    const { cacheConfig, localMutations } = mockState;

    wrapper = shallowMountExtended(RunnerBulkDelete, {
      apolloProvider: createMockApollo(undefined, undefined, cacheConfig),
      provide: {
        localMutations,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    mockState = createLocalState();

    jest
      .spyOn(mockState.cacheConfig.typePolicies.Query.fields, 'checkedRunnerIds')
      .mockImplementation(() => mockCheckedRunnerIds);
  });

  afterEach(() => {
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
    count | ids                                 | text
    ${1}  | ${['gid:Runner/1']}                 | ${'1 runner'}
    ${2}  | ${['gid:Runner/1', 'gid:Runner/2']} | ${'2 runners'}
  `('When $count runner(s) are checked', ({ count, ids, text }) => {
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
      expect(confirmAction).toHaveBeenCalledTimes(0);

      findDeleteBtn().vm.$emit('click');

      expect(confirmAction).toHaveBeenCalledTimes(1);

      const [, confirmOptions] = confirmAction.mock.calls[0];
      const { title, modalHtmlMessage, primaryBtnText } = confirmOptions;

      expect(title).toMatch(text);
      expect(primaryBtnText).toMatch(text);
      expect(modalHtmlMessage).toMatch(`<strong>${count}</strong>`);
    });
  });
});
