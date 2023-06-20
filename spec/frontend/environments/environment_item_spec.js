import { mount } from '@vue/test-utils';
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { format } from 'timeago.js';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import ActionsComponent from '~/environments/components/environment_actions.vue';
import DeleteComponent from '~/environments/components/environment_delete.vue';
import ExternalUrlComponent from '~/environments/components/environment_external_url.vue';
import EnvironmentItem from '~/environments/components/environment_item.vue';
import PinComponent from '~/environments/components/environment_pin.vue';
import RollbackComponent from '~/environments/components/environment_rollback.vue';
import StopComponent from '~/environments/components/environment_stop.vue';
import TerminalButtonComponent from '~/environments/components/environment_terminal_button.vue';
import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';
import { environment, folder, tableData } from './mock_data';

describe('Environment item', () => {
  let wrapper;
  let tracking;

  const factory = (options = {}) => {
    wrapper = mount(EnvironmentItem, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        model: environment,
        tableData,
      },
    });

    tracking = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  const findAutoStop = () => wrapper.find('.js-auto-stop');
  const findUpcomingDeployment = () => wrapper.find('[data-testid="upcoming-deployment"]');
  const findLastDeployment = () => wrapper.find('[data-testid="environment-deployment-id-cell"]');
  const findUpcomingDeploymentContent = () =>
    wrapper.find('[data-testid="upcoming-deployment-content"]');
  const findUpcomingDeploymentStatusLink = () =>
    wrapper.find('[data-testid="upcoming-deployment-status-link"]');
  const findLastDeploymentAvatarLink = () => findLastDeployment().findComponent(GlAvatarLink);
  const findLastDeploymentAvatar = () => findLastDeployment().findComponent(GlAvatar);
  const findUpcomingDeploymentAvatarLink = () =>
    findUpcomingDeployment().findComponent(GlAvatarLink);
  const findUpcomingDeploymentAvatar = () => findUpcomingDeployment().findComponent(GlAvatar);

  describe('when item is not folder', () => {
    it('should render environment name', () => {
      expect(wrapper.find('.environment-name').text()).toContain(environment.name);
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {
        expect(wrapper.find('.deployment-column span').text()).toContain(
          environment.last_deployment.iid.toString(),
        );

        expect(wrapper.find('.deployment-column span').text()).toContain('#');
      });

      it('should render last deployment date', () => {
        const formattedDate = format(environment.last_deployment.deployed_at);

        expect(wrapper.find('.environment-created-date-timeago').text()).toContain(formattedDate);
      });

      it('should not render the delete button', () => {
        expect(wrapper.findComponent(DeleteComponent).exists()).toBe(false);
      });

      describe('With user information', () => {
        it('should render user avatar with link to profile', () => {
          const avatarLink = findLastDeploymentAvatarLink();
          const avatar = findLastDeploymentAvatar();
          const { username, avatar_url: src, web_url } = environment.last_deployment.user;

          expect(avatarLink.attributes('href')).toBe(web_url);
          expect(avatar.props()).toMatchObject({
            src,
            entityName: username,
          });
          expect(avatar.attributes()).toMatchObject({
            title: username,
            alt: `${username}'s avatar`,
          });
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
            const avatarLink = findUpcomingDeploymentAvatarLink();
            const avatar = findUpcomingDeploymentAvatar();
            const { username, avatar_url: src, web_url } = environment.upcoming_deployment.user;

            expect(findUpcomingDeploymentContent().text()).toMatchInterpolatedText('#27 by');
            expect(avatarLink.attributes('href')).toBe(web_url);
            expect(avatar.props()).toMatchObject({
              src,
              entityName: username,
            });
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
                tableData,
              },
            });
          });

          it('should still render the build ID and user avatar', () => {
            const avatarLink = findUpcomingDeploymentAvatarLink();
            const avatar = findUpcomingDeploymentAvatar();
            const { username, avatar_url: src, web_url } = environment.upcoming_deployment.user;

            expect(findUpcomingDeploymentContent().text()).toMatchInterpolatedText('#27 by');
            expect(avatarLink.attributes('href')).toBe(web_url);
            expect(avatar.props()).toMatchObject({
              src,
              entityName: username,
            });
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
              tableData,
              shouldShowAutoStopDate: true,
            },
          });
        });

        it('should not render a date', () => {
          expect(findAutoStop().exists()).toBe(false);
        });

        it('should not render the auto-stop button', () => {
          expect(wrapper.findComponent(PinComponent).exists()).toBe(false);
        });
      });

      describe('With auto-stop date', () => {
        describe('in the future', () => {
          let pin;

          const futureDate = new Date(Date.now() + 100000);
          beforeEach(() => {
            factory({
              propsData: {
                model: {
                  ...environment,
                  auto_stop_at: futureDate,
                },
                tableData,
                shouldShowAutoStopDate: true,
              },
            });
            tracking = mockTracking(undefined, wrapper.element, jest.spyOn);

            pin = wrapper.findComponent(PinComponent);
          });

          it('renders the date', () => {
            expect(findAutoStop().text()).toContain(format(futureDate));
          });

          it('should render the auto-stop button', () => {
            expect(pin.exists()).toBe(true);
          });

          it('should tracks clicks', () => {
            pin.trigger('click');

            expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
              label: 'environment_pin',
            });
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
                tableData,
                shouldShowAutoStopDate: true,
              },
            });
          });

          it('should not render a date', () => {
            expect(findAutoStop().exists()).toBe(false);
          });

          it('should not render the suto-stop button', () => {
            expect(wrapper.findComponent(PinComponent).exists()).toBe(false);
          });
        });
      });
    });

    describe('With manual actions', () => {
      let actions;

      beforeEach(() => {
        actions = wrapper.findComponent(ActionsComponent);
      });

      it('should render actions component', () => {
        expect(actions.exists()).toBe(true);
      });

      it('should track clicks', () => {
        actions.trigger('click');
        expect(tracking).toHaveBeenCalledWith('_category_', 'click_dropdown', {
          label: 'environment_actions',
        });
      });
    });

    describe('With external URL', () => {
      let externalUrl;

      beforeEach(() => {
        externalUrl = wrapper.findComponent(ExternalUrlComponent);
      });

      it('should render external url component', () => {
        expect(externalUrl.exists()).toBe(true);
      });

      it('should track clicks', () => {
        externalUrl.trigger('click');
        expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'environment_url',
        });
      });
    });

    describe('With stop action', () => {
      let stop;

      beforeEach(() => {
        stop = wrapper.findComponent(StopComponent);
      });

      it('should render stop action component', () => {
        expect(stop.exists()).toBe(true);
      });

      it('should track clicks', () => {
        stop.trigger('click');
        expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'environment_stop',
        });
      });
    });

    describe('With retry action', () => {
      let rollback;

      beforeEach(() => {
        rollback = wrapper.findComponent(RollbackComponent);
      });

      it('should render rollback component', () => {
        expect(rollback.exists()).toBe(true);
      });

      it('should track clicks', () => {
        rollback.trigger('click');
        expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'environment_rollback',
        });
      });
    });

    describe('With terminal path', () => {
      let terminal;

      beforeEach(() => {
        terminal = wrapper.findComponent(TerminalButtonComponent);
      });

      it('should render terminal action component', () => {
        expect(terminal.exists()).toBe(true);
      });

      it('should track clicks', () => {
        triggerEvent(terminal.element);
        expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
          label: 'environment_terminal',
        });
      });
    });
  });

  describe('When item is folder', () => {
    beforeEach(() => {
      factory({
        propsData: {
          model: folder,
          tableData,
        },
      });
    });

    it('should render folder icon and name', () => {
      expect(wrapper.find('.folder-name').text()).toContain(folder.name);
      expect(wrapper.find('.folder-icon')).toBeDefined();
    });

    it('should render the number of children in a badge', () => {
      expect(wrapper.find('.folder-name .badge').text()).toContain(folder.size.toString());
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
      expect(findLastDeployment().exists()).toBe(false);
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
      expect(wrapper.findComponent(DeleteComponent).exists()).toBe(true);
    });

    it('should trigger a tracking event', async () => {
      tracking = mockTracking(undefined, wrapper.element, jest.spyOn);

      await wrapper.findComponent(DeleteComponent).trigger('click');

      expect(tracking).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'environment_delete',
      });
    });
  });
});
