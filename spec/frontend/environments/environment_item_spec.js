import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import { format } from 'timeago.js';
import DeleteComponent from '~/environments/components/environment_delete.vue';
import EnvironmentItem from '~/environments/components/environment_item.vue';
import PinComponent from '~/environments/components/environment_pin.vue';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import { environment, folder, tableData } from './mock_data';

describe('Environment item', () => {
  let wrapper;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = mount(EnvironmentItem, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        model: environment,
        canReadEnvironment: true,
        tableData,
      },
    });
  });

  const findAutoStop = () => wrapper.find('.js-auto-stop');
  const findUpcomingDeployment = () => wrapper.find('[data-testid="upcoming-deployment"]');
  const findUpcomingDeploymentContent = () =>
    wrapper.find('[data-testid="upcoming-deployment-content"]');
  const findUpcomingDeploymentStatusLink = () =>
    wrapper.find('[data-testid="upcoming-deployment-status-link"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when item is not folder', () => {
    it('should render environment name', () => {
      expect(wrapper.find('.environment-name').text()).toContain(environment.name);
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {
        expect(wrapper.find('.deployment-column span').text()).toContain(
          environment.last_deployment.iid,
        );

        expect(wrapper.find('.deployment-column span').text()).toContain('#');
      });

      it('should render last deployment date', () => {
        const formattedDate = format(environment.last_deployment.deployed_at);

        expect(wrapper.find('.environment-created-date-timeago').text()).toContain(formattedDate);
      });

      it('should not render the delete button', () => {
        expect(wrapper.find(DeleteComponent).exists()).toBe(false);
      });

      describe('With user information', () => {
        it('should render user avatar with link to profile', () => {
          expect(wrapper.find('.js-deploy-user-container').attributes('href')).toEqual(
            environment.last_deployment.user.web_url,
          );
        });
      });

      describe('With build url', () => {
        it('should link to build url provided', () => {
          expect(wrapper.find('.build-link').attributes('href')).toEqual(
            environment.last_deployment.deployable.build_path,
          );
        });

        it('should render deployable name and id', () => {
          expect(wrapper.find('.build-link').attributes('href')).toEqual(
            environment.last_deployment.deployable.build_path,
          );
        });
      });

      describe('With commit information', () => {
        it('should render commit component', () => {
          expect(wrapper.find('.js-commit-component')).toBeDefined();
        });
      });

      describe('When the envionment has an upcoming deployment', () => {
        describe('When the upcoming deployment has a deployable', () => {
          it('should render the build ID and user', () => {
            expect(findUpcomingDeploymentContent().text()).toMatchInterpolatedText(
              '#27 by upcoming-username',
            );
          });

          it('should render a status icon with a link and tooltip', () => {
            expect(findUpcomingDeploymentStatusLink().exists()).toBe(true);

            expect(findUpcomingDeploymentStatusLink().attributes().href).toBe(
              '/root/environment-test/-/jobs/892',
            );

            expect(findUpcomingDeploymentStatusLink().attributes().title).toBe(
              'Deployment running',
            );
          });
        });

        describe('When the deployment does not have a deployable', () => {
          beforeEach(() => {
            const environmentWithoutDeployable = cloneDeep(environment);
            delete environmentWithoutDeployable.upcoming_deployment.deployable;

            factory({
              propsData: {
                model: environmentWithoutDeployable,
                canReadEnvironment: true,
                tableData,
              },
            });
          });

          it('should still renders the build ID and user', () => {
            expect(findUpcomingDeploymentContent().text()).toMatchInterpolatedText(
              '#27 by upcoming-username',
            );
          });

          it('should not render the status icon', () => {
            expect(findUpcomingDeploymentStatusLink().exists()).toBe(false);
          });
        });
      });

      describe('Without upcoming deployment', () => {
        beforeEach(() => {
          const environmentWithoutUpcomingDeployment = cloneDeep(environment);
          delete environmentWithoutUpcomingDeployment.upcoming_deployment;

          factory({
            propsData: {
              model: environmentWithoutUpcomingDeployment,
              canReadEnvironment: true,
              tableData,
            },
          });
        });

        it('should not render anything in the upcoming deployment column', () => {
          expect(findUpcomingDeploymentContent().exists()).toBe(false);
        });
      });

      describe('Without auto-stop date', () => {
        beforeEach(() => {
          factory({
            propsData: {
              model: environment,
              canReadEnvironment: true,
              tableData,
              shouldShowAutoStopDate: true,
            },
          });
        });

        it('should not render a date', () => {
          expect(findAutoStop().exists()).toBe(false);
        });

        it('should not render the auto-stop button', () => {
          expect(wrapper.find(PinComponent).exists()).toBe(false);
        });
      });

      describe('With auto-stop date', () => {
        describe('in the future', () => {
          const futureDate = new Date(Date.now() + 100000);
          beforeEach(() => {
            factory({
              propsData: {
                model: {
                  ...environment,
                  auto_stop_at: futureDate,
                },
                canReadEnvironment: true,
                tableData,
                shouldShowAutoStopDate: true,
              },
            });
          });

          it('renders the date', () => {
            expect(findAutoStop().text()).toContain(format(futureDate));
          });

          it('should render the auto-stop button', () => {
            expect(wrapper.find(PinComponent).exists()).toBe(true);
          });
        });

        describe('in the past', () => {
          const pastDate = new Date(differenceInMilliseconds(100000));
          beforeEach(() => {
            factory({
              propsData: {
                model: {
                  ...environment,
                  auto_stop_at: pastDate,
                },
                canReadEnvironment: true,
                tableData,
                shouldShowAutoStopDate: true,
              },
            });
          });

          it('should not render a date', () => {
            expect(findAutoStop().exists()).toBe(false);
          });

          it('should not render the suto-stop button', () => {
            expect(wrapper.find(PinComponent).exists()).toBe(false);
          });
        });
      });
    });

    describe('With manual actions', () => {
      it('should render actions component', () => {
        expect(wrapper.find('.js-manual-actions-container')).toBeDefined();
      });
    });

    describe('With external URL', () => {
      it('should render external url component', () => {
        expect(wrapper.find('.js-external-url-container')).toBeDefined();
      });
    });

    describe('With stop action', () => {
      it('should render stop action component', () => {
        expect(wrapper.find('.js-stop-component-container')).toBeDefined();
      });
    });

    describe('With retry action', () => {
      it('should render rollback component', () => {
        expect(wrapper.find('.js-rollback-component-container')).toBeDefined();
      });
    });
  });

  describe('When item is folder', () => {
    beforeEach(() => {
      factory({
        propsData: {
          model: folder,
          canReadEnvironment: true,
          tableData,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should render folder icon and name', () => {
      expect(wrapper.find('.folder-name').text()).toContain(folder.name);
      expect(wrapper.find('.folder-icon')).toBeDefined();
    });

    it('should render the number of children in a badge', () => {
      expect(wrapper.find('.folder-name .badge').text()).toContain(folder.size);
    });

    it('should not render the "Upcoming deployment" column', () => {
      expect(findUpcomingDeployment().exists()).toBe(false);
    });

    it('should set the name cell to be full width', () => {
      expect(wrapper.find('[data-testid="environment-name-cell"]').classes('section-100')).toBe(
        true,
      );
    });

    it('should hide non-folder properties', () => {
      expect(wrapper.find('[data-testid="environment-deployment-id-cell"]').exists()).toBe(false);
      expect(wrapper.find('[data-testid="environment-build-cell"]').exists()).toBe(false);
    });
  });

  describe('When environment can be deleted', () => {
    beforeEach(() => {
      factory({
        propsData: {
          model: {
            can_delete: true,
            delete_path: 'http://0.0.0.0:3000/api/v4/projects/8/environments/45',
          },
          tableData,
        },
      });
    });

    it('should render the delete button', () => {
      expect(wrapper.find(DeleteComponent).exists()).toBe(true);
    });
  });
});
