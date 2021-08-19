import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import eventHub from '~/environments/event_hub';

describe('Confirm Rollback Modal Component', () => {
  let environment;
  let component;

  const envWithLastDeployment = {
    name: 'test',
    last_deployment: {
      commit: {
        short_id: 'abc0123',
      },
    },
    modalId: 'test',
  };

  const envWithoutLastDeployment = {
    name: 'test',
    modalId: 'test',
    commitShortSha: 'abc0123',
    commitUrl: 'test/-/commit/abc0123',
  };

  const retryPath = 'test/-/jobs/123/retry';

  const createComponent = (props = {}) => {
    component = shallowMount(ConfirmRollbackModal, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  describe.each`
    hasMultipleCommits | environmentData             | retryUrl     | primaryPropsAttrs
    ${true}            | ${envWithLastDeployment}    | ${null}      | ${[{ variant: 'danger' }]}
    ${false}           | ${envWithoutLastDeployment} | ${retryPath} | ${[{ variant: 'danger' }, { 'data-method': 'post' }, { href: retryPath }]}
  `(
    'when hasMultipleCommits=$hasMultipleCommits',
    ({ hasMultipleCommits, environmentData, retryUrl, primaryPropsAttrs }) => {
      beforeEach(() => {
        environment = environmentData;
      });

      it('should show "Rollback" when isLastDeployment is false', () => {
        createComponent({
          environment: {
            ...environment,
            isLastDeployment: false,
          },
          hasMultipleCommits,
          retryUrl,
        });
        const modal = component.find(GlModal);

        expect(modal.attributes('title')).toContain('Rollback');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Rollback');
        expect(modal.props('actionPrimary').attributes).toEqual(primaryPropsAttrs);
        expect(modal.text()).toContain('commit abc0123');
        expect(modal.text()).toContain('Are you sure you want to continue?');
      });

      it('should show "Re-deploy" when isLastDeployment is true', () => {
        createComponent({
          environment: {
            ...environment,
            isLastDeployment: true,
          },
          hasMultipleCommits,
        });

        const modal = component.find(GlModal);

        expect(modal.attributes('title')).toContain('Re-deploy');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Re-deploy');
        expect(modal.text()).toContain('commit abc0123');
        expect(modal.text()).toContain('Are you sure you want to continue?');
      });

      it('should emit the "rollback" event when "ok" is clicked', () => {
        const env = { ...environmentData, isLastDeployment: true };

        createComponent({
          environment: env,
          hasMultipleCommits,
        });

        const eventHubSpy = jest.spyOn(eventHub, '$emit');
        const modal = component.find(GlModal);
        modal.vm.$emit('ok');

        expect(eventHubSpy).toHaveBeenCalledWith('rollbackEnvironment', env);
      });
    },
  );
});
