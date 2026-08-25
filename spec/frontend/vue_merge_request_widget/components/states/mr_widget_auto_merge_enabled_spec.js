import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import autoMergeEnabledComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue';
import autoMergeEnabledQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/auto_merge_enabled.query.graphql';
import { MWCP_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

Vue.use(VueApollo);

let wrapper;

function buildMergeRequestState(props, stateOverride = {}) {
  return {
    __typename: 'MergeRequest',
    id: '1',
    autoMergeStrategy: props.autoMergeStrategy,
    mergeUser: {
      id: props.mergeUserId,
      name: '',
      username: '',
      webUrl: '',
      avatarUrl: '',
      ...props.setToAutoMergeBy,
    },
    targetBranch: props.targetBranch,
    shouldRemoveSourceBranch: props.shouldRemoveSourceBranch,
    forceRemoveSourceBranch: props.shouldRemoveSourceBranch,
    userPermissions: {
      removeSourceBranch: props.canRemoveSourceBranch,
    },
    ...stateOverride,
  };
}

function buildQueryResponse(props, stateOverride = {}, mergeTrainsCount = 0) {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: '1',
        mergeRequest: buildMergeRequestState(props, stateOverride),
        mergeTrains: {
          __typename: 'MergeTrainConnection',
          nodes: [
            {
              cars: {
                count: mergeTrainsCount,
              },
            },
          ],
        },
      },
    },
  };
}

function factory(propsData, stateOverride = {}) {
  const handler = jest.fn().mockResolvedValue(buildQueryResponse(propsData, stateOverride));

  wrapper = extendedWrapper(
    mount(autoMergeEnabledComponent, {
      apolloProvider: createMockApollo([[autoMergeEnabledQuery, handler]]),
      propsData: {
        mr: propsData,
        service: new MRWidgetService({}),
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
  autoMergeStrategy: MWCP_MERGE_STRATEGY,
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
      it('should return "Cancel" if MWCP is selected', async () => {
        factory({
          ...defaultMrProps(),
          autoMergeStrategy: MWCP_MERGE_STRATEGY,
        });

        await waitForPromises();

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

        await waitForPromises();

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
        expect(eventHub.$emit).toHaveBeenCalledWith('mr-widget-update-requested');
      });
    });
  });

  describe('template', () => {
    it('should disable cancel auto merge button when the action is in progress', async () => {
      factory({
        ...defaultMrProps(),
      });

      await waitForPromises();

      await findCancelAutoMergeButton().trigger('click');

      expect(wrapper.findComponent('.js-cancel-auto-merge').props('loading')).toBe(true);
    });

    it('should render the status text as "to be merged automatically..." if MWCP is selected', async () => {
      factory({
        ...defaultMrProps(),
        autoMergeStrategy: MWCP_MERGE_STRATEGY,
      });

      await waitForPromises();

      expect(getStatusText()).toContain('to be merged automatically when all merge checks pass');
    });
  });
});
