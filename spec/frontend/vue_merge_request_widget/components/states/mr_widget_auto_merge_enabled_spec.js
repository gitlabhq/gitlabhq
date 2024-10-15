import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import autoMergeEnabledComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue';
import { MWPS_MERGE_STRATEGY, MWCP_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

let wrapper;

function convertPropsToGraphqlState(props) {
  return {
    autoMergeStrategy: props.autoMergeStrategy,
    cancelAutoMergePath: 'http://text.com',
    mergeUser: {
      id: props.mergeUserId,
      ...props.setToAutoMergeBy,
    },
    targetBranch: props.targetBranch,
    targetBranchCommitsPath: props.targetBranchPath,
    shouldRemoveSourceBranch: props.shouldRemoveSourceBranch,
    forceRemoveSourceBranch: props.shouldRemoveSourceBranch,
    userPermissions: {
      removeSourceBranch: props.canRemoveSourceBranch,
    },
  };
}

function factory(propsData, stateOverride = {}) {
  wrapper = extendedWrapper(
    mount(autoMergeEnabledComponent, {
      propsData: {
        mr: propsData,
        service: new MRWidgetService({}),
      },
      data() {
        return {
          state: {
            mergeRequest: {
              ...convertPropsToGraphqlState(propsData),
              ...stateOverride,
            },
          },
        };
      },
      mocks: {
        $apollo: {
          queries: {
            state: { loading: false },
          },
        },
      },
    }),
  );
}

const targetBranchPath = '/foo/bar';
const targetBranch = 'foo';
const sha = '1EA2EZ34';
const defaultMrProps = () => ({
  shouldRemoveSourceBranch: false,
  canRemoveSourceBranch: true,
  canCancelAutomaticMerge: true,
  mergeUserId: 1,
  currentUserId: 1,
  setToAutoMergeBy: {},
  sha,
  targetBranchPath,
  targetBranch,
  autoMergeStrategy: MWPS_MERGE_STRATEGY,
});

const getStatusText = () => wrapper.findByTestId('statusText').text();
const findCancelAutoMergeButton = () => wrapper.find('[data-testid="cancelAutomaticMergeButton"]');

describe('MRWidgetAutoMergeEnabled', () => {
  let oldWindowGl;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    oldWindowGl = window.gl;
    window.gl = {
      mrWidgetData: {
        defaultAvatarUrl: 'no_avatar.png',
      },
    };
  });

  afterEach(() => {
    mock.restore();
    window.gl = oldWindowGl;
  });

  describe('computed', () => {
    describe('cancelButtonText', () => {
      it('should return "Cancel" if MWPS is selected', () => {
        factory({
          ...defaultMrProps(),
          autoMergeStrategy: MWPS_MERGE_STRATEGY,
        });

        expect(wrapper.findByTestId('cancelAutomaticMergeButton').text()).toBe('Cancel auto-merge');
      });
    });
  });

  describe('methods', () => {
    describe('cancelAutomaticMerge', () => {
      it('should set flag and call service then tell main component to update the widget with data', async () => {
        factory({
          ...defaultMrProps(),
        });
        const mrObj = {
          is_new_mr_data: true,
        };
        jest.spyOn(wrapper.vm.service, 'cancelAutomaticMerge').mockReturnValue(
          new Promise((resolve) => {
            resolve({
              data: mrObj,
            });
          }),
        );

        wrapper.vm.cancelAutomaticMerge();

        await waitForPromises();

        expect(wrapper.vm.isCancellingAutoMerge).toBe(true);
        expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
      });
    });
  });

  describe('template', () => {
    it('should disable cancel auto merge button when the action is in progress', async () => {
      factory({
        ...defaultMrProps(),
      });

      await findCancelAutoMergeButton().trigger('click');

      expect(wrapper.find('.js-cancel-auto-merge').props('loading')).toBe(true);
    });

    it('should render the status text as "...to merged automatically" if MWPS is selected', () => {
      factory({
        ...defaultMrProps(),
        autoMergeStrategy: MWPS_MERGE_STRATEGY,
      });

      expect(getStatusText()).toContain('to be merged automatically when the pipeline succeeds');
    });

    it('should render the status text as "to be merged automatically..." if MWCP is selected', () => {
      factory({
        ...defaultMrProps(),
        autoMergeStrategy: MWCP_MERGE_STRATEGY,
      });

      expect(getStatusText()).toContain('to be merged automatically when all merge checks pass');
    });

    it('should render the cancel button as "Cancel" if MWPS is selected', () => {
      factory({
        ...defaultMrProps(),
        autoMergeStrategy: MWPS_MERGE_STRATEGY,
      });

      const cancelButtonText = trimText(wrapper.find('.js-cancel-auto-merge').text());

      expect(cancelButtonText).toBe('Cancel auto-merge');
    });
  });
});
