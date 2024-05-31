import { GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { triggerEvent } from 'helpers/tracking_helper';
import { InternalEvents } from '~/tracking';
import migrateJenkinsComponent from '~/vue_merge_request_widget/components/mr_widget_migrate_jenkins.vue';
import { JM_EVENT_NAME, JM_MIGRATION_LINK } from '~/vue_merge_request_widget/constants';

describe('MrWidgetMigrateJenkins', () => {
  describe('template', () => {
    let wrapper;

    describe('core functionality', () => {
      const findCloseButton = () => wrapper.find('[data-testid="close"]');
      const migrationPlanLink = () => wrapper.find('[data-testid="migration-plan"]');

      beforeEach(() => {
        wrapper = mount(migrateJenkinsComponent, {
          propsData: {
            humanAccess: 'maintainer',
          },
          stubs: {
            GlSprintf,
          },
        });
      });

      it('renders the expected text', () => {
        const titleText = 'Migrate to GitLab CI/CD from Jenkins Start with migration plan';
        const bodyText =
          'Take advantage of simple, scalable pipelines and CI/CD enabled features. You can view integration results, security scans, tests, code coverage and more directly in merge requests!';
        const componentText = wrapper.text();

        expect(componentText).toContain(titleText);
        expect(componentText).toContain(bodyText);
      });

      it('renders the start migration link', () => {
        expect(migrationPlanLink().attributes('href')).toBe(JM_MIGRATION_LINK);
      });

      it('emits an event when the close button is clicked', async () => {
        const closeButton = findCloseButton();
        await closeButton.trigger('click');

        expect(wrapper.emitted('dismiss')).toEqual([[]]);
      });

      describe('tracking', () => {
        it('sends an event when the close button is clicked', () => {
          jest.spyOn(InternalEvents, 'trackEvent');

          const okBtn = findCloseButton();
          triggerEvent(okBtn.element);

          expect(InternalEvents.trackEvent).toHaveBeenCalledWith(JM_EVENT_NAME, {}, undefined);
        });
      });
    });
  });
});
