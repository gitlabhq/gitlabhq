import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import SecurityConfigurationApp from 'ee_else_ce/security_configuration/components/app.vue';
import SecurityConfigurationProvider from '~/security_configuration/components/security_configuration_provider.vue';
import { initSecurityConfiguration } from '~/security_configuration';

jest.mock('~/lib/utils/vue3compat/init_vue_app');
jest.mock('~/lib/graphql', () => jest.fn());

describe('initSecurityConfiguration', () => {
  describe.each([false, true])('when GraphQL mode is %s', (useGraphql) => {
    beforeEach(() => {
      const el = document.createElement('div');
      Object.assign(el.dataset, {
        projectId: '123',
        projectFullPath: 'group/project',
        useGraphql: String(useGraphql),
      });
      initSecurityConfiguration(el);
    });

    it('mounts the matching app with project context', () => {
      expect(initVueApp).toHaveBeenCalledWith(
        expect.objectContaining({
          component: useGraphql ? SecurityConfigurationProvider : SecurityConfigurationApp,
          provide: expect.objectContaining({ projectFullPath: 'group/project' }),
        }),
      );
    });
  });
});
