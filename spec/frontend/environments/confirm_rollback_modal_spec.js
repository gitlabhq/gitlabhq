import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { trimText } from 'helpers/text_helper';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
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

  const envWithLastDeploymentGraphql = {
    name: 'test',
    lastDeployment: {
      commit: {
        shortId: 'abc0123',
      },
      isLast: true,
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

  const createComponent = (props = {}, options = {}) => {
    component = shallowMount(ConfirmRollbackModal, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
      ...options,
    });
  };

  const findModal = () => component.findComponent(GlModal);

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
        const modal = findModal();

        expect(modal.attributes('title')).toContain('Rollback');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Rollback environment');
        expect(modal.props('actionPrimary').attributes).toEqual(primaryPropsAttrs);
        expect(trimText(modal.text())).toContain('commit abc0123');
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

        const modal = findModal();

        expect(modal.attributes('title')).toContain('Re-deploy');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Re-deploy environment');
        expect(trimText(modal.text())).toContain('commit abc0123');
        expect(modal.text()).toContain('Are you sure you want to continue?');
      });

      it('should emit the "rollback" event when "ok" is clicked', () => {
        const env = { ...environmentData, isLastDeployment: true };

        createComponent({
          environment: env,
          hasMultipleCommits,
        });

        const eventHubSpy = jest.spyOn(eventHub, '$emit');
        const modal = findModal();
        modal.vm.$emit('ok');

        expect(eventHubSpy).toHaveBeenCalledWith('rollbackEnvironment', env);
      });
    },
  );

  describe('graphql', () => {
    describe.each`
      hasMultipleCommits | environmentData                 | retryUrl     | primaryPropsAttrs
      ${true}            | ${envWithLastDeploymentGraphql} | ${null}      | ${[{ variant: 'danger' }]}
      ${false}           | ${envWithoutLastDeployment}     | ${retryPath} | ${[{ variant: 'danger' }, { 'data-method': 'post' }, { href: retryPath }]}
    `(
      'when hasMultipleCommits=$hasMultipleCommits',
      ({ hasMultipleCommits, environmentData, retryUrl, primaryPropsAttrs }) => {
        Vue.use(VueApollo);

        let apolloProvider;
        let rollbackResolver;

        beforeEach(() => {
          rollbackResolver = jest.fn();
          apolloProvider = createMockApollo([], {
            Mutation: { rollbackEnvironment: rollbackResolver },
          });
          environment = environmentData;
        });

        it('should set contain the commit hash and ask for confirmation', () => {
          createComponent(
            {
              environment: {
                ...environment,
                lastDeployment: {
                  ...environment.lastDeployment,
                  isLast: false,
                },
              },
              hasMultipleCommits,
              retryUrl,
              graphql: true,
            },
            { apolloProvider },
          );
          const modal = findModal();

          expect(trimText(modal.text())).toContain('commit abc0123');
          expect(modal.text()).toContain('Are you sure you want to continue?');
        });

        it('should show "Rollback" when isLastDeployment is false', () => {
          createComponent(
            {
              environment: {
                ...environment,
                lastDeployment: {
                  ...environment.lastDeployment,
                  isLast: false,
                },
              },
              hasMultipleCommits,
              retryUrl,
              graphql: true,
            },
            { apolloProvider },
          );
          const modal = findModal();

          expect(modal.attributes('title')).toContain('Rollback');
          expect(modal.attributes('title')).toContain('test');
          expect(modal.props('actionPrimary').text).toBe('Rollback environment');
          expect(modal.props('actionPrimary').attributes).toEqual(primaryPropsAttrs);
        });

        it('should show "Re-deploy" when isLastDeployment is true', () => {
          createComponent(
            {
              environment: {
                ...environment,
                lastDeployment: {
                  ...environment.lastDeployment,
                  isLast: true,
                },
              },
              hasMultipleCommits,
              graphql: true,
            },
            { apolloProvider },
          );

          const modal = findModal();

          expect(modal.attributes('title')).toContain('Re-deploy');
          expect(modal.attributes('title')).toContain('test');
          expect(modal.props('actionPrimary').text).toBe('Re-deploy environment');
        });

        it('should commit the "rollback" mutation when "ok" is clicked', async () => {
          const env = { ...environmentData, isLastDeployment: true };

          createComponent(
            {
              environment: env,
              hasMultipleCommits,
              graphql: true,
            },
            { apolloProvider },
          );

          const modal = findModal();
          modal.vm.$emit('ok');

          await nextTick();
          expect(rollbackResolver).toHaveBeenCalledWith(
            expect.anything(),
            { environment: env },
            expect.anything(),
            expect.anything(),
          );
        });

        it('should emit the "rollback" event when "ok" is clicked', async () => {
          const env = { ...environmentData, isLastDeployment: true };

          createComponent(
            {
              environment: env,
              hasMultipleCommits,
              graphql: true,
            },
            { apolloProvider },
          );

          const modal = findModal();
          modal.vm.$emit('ok');

          await waitForPromises();
          expect(component.emitted('rollback')).toEqual([[]]);
        });
      },
    );
  });
});
