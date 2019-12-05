import { mount } from '@vue/test-utils';
import DeploymentComponent from '~/vue_merge_request_widget/components/deployment/deployment.vue';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment/deployment_info.vue';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import DeploymentStopButton from '~/vue_merge_request_widget/components/deployment/deployment_stop_button.vue';
import {
  CREATED,
  RUNNING,
  SUCCESS,
  FAILED,
  CANCELED,
} from '~/vue_merge_request_widget/components/deployment/constants';
import deploymentMockData from './deployment_mock_data';

const deployDetail = {
  playable_build: {
    retry_path: '/root/test-deployments/-/jobs/1131/retry',
    play_path: '/root/test-deployments/-/jobs/1131/play',
  },
  isManual: true,
};

describe('Deployment component', () => {
  let wrapper;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = mount(DeploymentComponent, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        showMetrics: false,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('always renders DeploymentInfo', () => {
    expect(wrapper.find(DeploymentInfo).exists()).toBe(true);
  });

  describe('status message and buttons', () => {
    const noActions = [];
    const noDetails = { isManual: false };
    const deployGroup = [DeploymentViewButton, DeploymentStopButton];

    describe.each`
      status      | previous | deploymentDetails | text                        | actionButtons
      ${CREATED}  | ${true}  | ${deployDetail}   | ${'Can deploy manually to'} | ${deployGroup}
      ${CREATED}  | ${true}  | ${noDetails}      | ${'Will deploy to'}         | ${deployGroup}
      ${CREATED}  | ${false} | ${deployDetail}   | ${'Can deploy manually to'} | ${noActions}
      ${CREATED}  | ${false} | ${noDetails}      | ${'Will deploy to'}         | ${noActions}
      ${RUNNING}  | ${true}  | ${deployDetail}   | ${'Deploying to'}           | ${deployGroup}
      ${RUNNING}  | ${true}  | ${noDetails}      | ${'Deploying to'}           | ${deployGroup}
      ${RUNNING}  | ${false} | ${deployDetail}   | ${'Deploying to'}           | ${noActions}
      ${RUNNING}  | ${false} | ${noDetails}      | ${'Deploying to'}           | ${noActions}
      ${SUCCESS}  | ${true}  | ${deployDetail}   | ${'Deployed to'}            | ${deployGroup}
      ${SUCCESS}  | ${true}  | ${noDetails}      | ${'Deployed to'}            | ${deployGroup}
      ${SUCCESS}  | ${false} | ${deployDetail}   | ${'Deployed to'}            | ${deployGroup}
      ${SUCCESS}  | ${false} | ${noDetails}      | ${'Deployed to'}            | ${deployGroup}
      ${FAILED}   | ${true}  | ${deployDetail}   | ${'Failed to deploy to'}    | ${deployGroup}
      ${FAILED}   | ${true}  | ${noDetails}      | ${'Failed to deploy to'}    | ${deployGroup}
      ${FAILED}   | ${false} | ${deployDetail}   | ${'Failed to deploy to'}    | ${noActions}
      ${FAILED}   | ${false} | ${noDetails}      | ${'Failed to deploy to'}    | ${noActions}
      ${CANCELED} | ${true}  | ${deployDetail}   | ${'Canceled deploy to'}     | ${deployGroup}
      ${CANCELED} | ${true}  | ${noDetails}      | ${'Canceled deploy to'}     | ${deployGroup}
      ${CANCELED} | ${false} | ${deployDetail}   | ${'Canceled deploy to'}     | ${noActions}
      ${CANCELED} | ${false} | ${noDetails}      | ${'Canceled deploy to'}     | ${noActions}
    `(
      '$status + previous: $previous + manual: $deploymentDetails.isManual',
      ({ status, previous, deploymentDetails, text, actionButtons }) => {
        beforeEach(() => {
          const previousOrSuccess = Boolean(previous || status === SUCCESS);
          const updatedDeploymentData = {
            status,
            deployed_at: previous ? deploymentMockData.deployed_at : null,
            deployed_at_formatted: previous ? deploymentMockData.deployed_at_formatted : null,
            external_url: previousOrSuccess ? deploymentMockData.external_url : null,
            external_url_formatted: previousOrSuccess
              ? deploymentMockData.external_url_formatted
              : null,
            stop_url: previousOrSuccess ? deploymentMockData.stop_url : null,
            details: deploymentDetails,
          };

          factory({
            propsData: {
              showMetrics: false,
              deployment: {
                ...deploymentMockData,
                ...updatedDeploymentData,
              },
            },
          });
        });

        it(`renders the text: ${text}`, () => {
          expect(wrapper.find(DeploymentInfo).text()).toContain(text);
        });

        if (actionButtons.length > 0) {
          describe('renders the expected button group', () => {
            actionButtons.forEach(button => {
              it(`renders ${button.name}`, () => {
                expect(wrapper.find(button).exists()).toBe(true);
              });
            });
          });
        }

        if (actionButtons.length === 0) {
          describe('does not render the button group', () => {
            [DeploymentViewButton, DeploymentStopButton].forEach(button => {
              it(`does not render ${button.name}`, () => {
                expect(wrapper.find(button).exists()).toBe(false);
              });
            });
          });
        }

        if (actionButtons.includes(DeploymentViewButton)) {
          it('renders the View button with expected text', () => {
            if (status === SUCCESS) {
              expect(wrapper.find(DeploymentViewButton).text()).toContain('View app');
            } else {
              expect(wrapper.find(DeploymentViewButton).text()).toContain('View previous app');
            }
          });
        }
      },
    );
  });

  describe('hasExternalUrls', () => {
    describe('when deployment has both external_url_formatted and external_url', () => {
      it('should return true', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(true);
      });

      it('should render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(true);
      });
    });

    describe('when deployment has no external_url_formatted', () => {
      beforeEach(() => {
        factory({
          propsData: {
            deployment: { ...deploymentMockData, external_url_formatted: null },
            showMetrics: false,
          },
        });
      });

      it('should return false', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(false);
      });

      it('should not render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(false);
      });
    });

    describe('when deployment has no external_url', () => {
      beforeEach(() => {
        factory({
          propsData: {
            deployment: { ...deploymentMockData, external_url: null },
            showMetrics: false,
          },
        });
      });

      it('should return false', () => {
        expect(wrapper.vm.hasExternalUrls).toEqual(false);
      });

      it('should not render the View Button', () => {
        expect(wrapper.find(DeploymentViewButton).exists()).toBe(false);
      });
    });
  });
});
