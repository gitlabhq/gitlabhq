import { mount } from '@vue/test-utils';
import { format } from 'timeago.js';
import EnvironmentItem from '~/environments/components/environment_item.vue';
import PinComponent from '~/environments/components/environment_pin.vue';

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

        it('should not render the suto-stop button', () => {
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
          const pastDate = new Date(Date.now() - 100000);
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
  });
});
