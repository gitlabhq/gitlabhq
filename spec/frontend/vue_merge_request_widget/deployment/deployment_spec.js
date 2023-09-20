import { mount } from '@vue/test-utils';
import {
  CREATED,
  RUNNING,
  SUCCESS,
  FAILED,
  CANCELED,
  SKIPPED,
} from '~/vue_merge_request_widget/components/deployment/constants';
import DeploymentComponent from '~/vue_merge_request_widget/components/deployment/deployment.vue';
import DeploymentInfo from '~/vue_merge_request_widget/components/deployment/deployment_info.vue';
import DeploymentViewButton from '~/vue_merge_request_widget/components/deployment/deployment_view_button.vue';
import {
  deploymentMockData,
  playDetails,
  retryDetails,
  mockRedeployProps,
} from './deployment_mock_data';

describe('Deployment component', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = mount(DeploymentComponent, options);
  };

  beforeEach(() => {
    factory({
      propsData: {
        deployment: deploymentMockData,
        showMetrics: false,
      },
    });
  });

  it('always renders DeploymentInfo', () => {
    expect(wrapper.findComponent(DeploymentInfo).exists()).toBe(true);
  });

  describe('status message and buttons', () => {
    const noActions = [];
    const noDetails = { isManual: false };
    const deployDetail = {
      ...playDetails,
      isManual: true,
    };

    const retryDetail = {
      ...retryDetails,
      isManual: true,
    };
    const defaultGroup = ['.js-deploy-url', '.js-stop-env'];
    const manualDeployGroup = ['.js-manual-deploy-action', ...defaultGroup];

    describe.each`
      status      | previous | deploymentDetails | text                             | actionButtons
      ${CREATED}  | ${true}  | ${deployDetail}   | ${'Can be manually deployed to'} | ${manualDeployGroup}
      ${CREATED}  | ${true}  | ${noDetails}      | ${'Will deploy to'}              | ${defaultGroup}
      ${CREATED}  | ${false} | ${deployDetail}   | ${'Can be manually deployed to'} | ${noActions}
      ${CREATED}  | ${false} | ${noDetails}      | ${'Will deploy to'}              | ${noActions}
      ${RUNNING}  | ${true}  | ${deployDetail}   | ${'Deploying to'}                | ${defaultGroup}
      ${RUNNING}  | ${true}  | ${noDetails}      | ${'Deploying to'}                | ${defaultGroup}
      ${RUNNING}  | ${false} | ${deployDetail}   | ${'Deploying to'}                | ${noActions}
      ${RUNNING}  | ${false} | ${noDetails}      | ${'Deploying to'}                | ${noActions}
      ${SUCCESS}  | ${true}  | ${deployDetail}   | ${'Deployed to'}                 | ${defaultGroup}
      ${SUCCESS}  | ${true}  | ${noDetails}      | ${'Deployed to'}                 | ${defaultGroup}
      ${SUCCESS}  | ${false} | ${deployDetail}   | ${'Deployed to'}                 | ${defaultGroup}
      ${SUCCESS}  | ${false} | ${noDetails}      | ${'Deployed to'}                 | ${defaultGroup}
      ${FAILED}   | ${true}  | ${retryDetail}    | ${'Failed to deploy to'}         | ${defaultGroup}
      ${FAILED}   | ${true}  | ${noDetails}      | ${'Failed to deploy to'}         | ${defaultGroup}
      ${FAILED}   | ${false} | ${retryDetail}    | ${'Failed to deploy to'}         | ${noActions}
      ${FAILED}   | ${false} | ${noDetails}      | ${'Failed to deploy to'}         | ${noActions}
      ${CANCELED} | ${true}  | ${deployDetail}   | ${'Canceled deployment to'}      | ${defaultGroup}
      ${CANCELED} | ${true}  | ${noDetails}      | ${'Canceled deployment to'}      | ${defaultGroup}
      ${CANCELED} | ${false} | ${deployDetail}   | ${'Canceled deployment to'}      | ${noActions}
      ${CANCELED} | ${false} | ${noDetails}      | ${'Canceled deployment to'}      | ${noActions}
      ${SKIPPED}  | ${true}  | ${deployDetail}   | ${'Skipped deployment to'}       | ${defaultGroup}
      ${SKIPPED}  | ${true}  | ${noDetails}      | ${'Skipped deployment to'}       | ${defaultGroup}
      ${SKIPPED}  | ${false} | ${deployDetail}   | ${'Skipped deployment to'}       | ${noActions}
      ${SKIPPED}  | ${false} | ${noDetails}      | ${'Skipped deployment to'}       | ${noActions}
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
          expect(wrapper.findComponent(DeploymentInfo).text()).toContain(text);
        });

        if (actionButtons.length > 0) {
          describe('renders the expected button group', () => {
            actionButtons.forEach((button) => {
              it(`renders ${button}`, () => {
                expect(wrapper.find(button).exists()).toBe(true);
              });
            });
          });
        }

        if (actionButtons.length === 0) {
          describe('does not render the button group', () => {
            defaultGroup.forEach((button) => {
              it(`does not render ${button}`, () => {
                expect(wrapper.find(button).exists()).toBe(false);
              });
            });
          });
        }

        if (actionButtons.includes(DeploymentViewButton)) {
          it('renders the View button with expected text', () => {
            if (status === SUCCESS) {
              expect(wrapper.findComponent(DeploymentViewButton).text()).toContain('View app');
            } else {
              expect(wrapper.findComponent(DeploymentViewButton).text()).toContain(
                'View latest app',
              );
            }
          });
        }
      },
    );

    describe('redeploy action', () => {
      beforeEach(() => {
        factory({
          propsData: {
            showMetrics: false,
            deployment: {
              ...deploymentMockData,
              ...mockRedeployProps,
            },
          },
        });
      });

      it('shows only the redeploy button', () => {
        expect(wrapper.find('.js-redeploy-action').exists()).toBe(true);
        expect(wrapper.find('.js-deploy-url').exists()).toBe(false);
        expect(wrapper.find('.js-stop-env').exists()).toBe(false);
        expect(wrapper.find('.js-manual-deploy-action').exists()).toBe(false);
      });
    });
  });

  describe('hasExternalUrls', () => {
    describe('when deployment has both external_url_formatted and external_url', () => {
      it('should render the View Button', () => {
        expect(wrapper.findComponent(DeploymentViewButton).exists()).toBe(true);
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

      it('should not render the View Button', () => {
        expect(wrapper.findComponent(DeploymentViewButton).exists()).toBe(false);
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

      it('should not render the View Button', () => {
        expect(wrapper.findComponent(DeploymentViewButton).exists()).toBe(false);
      });
    });
  });
});
