import { GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Component from '~/feature_flags/components/configure_feature_flags_modal.vue';

describe('Configure Feature Flags Modal', () => {
  const mockEvent = { preventDefault: jest.fn() };
  const provide = {
    projectName: 'fakeProjectName',
    featureFlagsHelpPagePath: '/help/path',
    featureFlagsClientLibrariesHelpPagePath: '/help/path/#flags',
    featureFlagsClientExampleHelpPagePath: '/feature-flags#clientexample',
    unleashApiUrl: '/api/url',
  };

  const propsData = {
    instanceId: 'instance-id-token',
    isRotating: false,
    hasRotateError: false,
    canUserRotateToken: true,
  };

  let wrapper;
  const factory = (props = {}, { mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(Component, {
      provide,
      stubs: { GlSprintf },
      propsData: {
        ...propsData,
        ...props,
      },
      ...options,
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findPrimaryAction = () => findGlModal().props('actionPrimary');
  const findSecondaryAction = () => findGlModal().props('actionSecondary');
  const findProjectNameInput = () => wrapper.find('#project_name_verification');
  const findDangerGlAlert = () =>
    wrapper.findAll(GlAlert).filter((c) => c.props('variant') === 'danger');

  describe('idle', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory);

    it('should have Primary and Secondary actions', () => {
      expect(findPrimaryAction().text).toBe('Close');
      expect(findSecondaryAction().text).toBe('Regenerate instance ID');
    });

    it('should default disable the primary action', () => {
      const [{ disabled }] = findSecondaryAction().attributes;
      expect(disabled).toBe(true);
    });

    it('should emit a `token` event when clicking on the Primary action', async () => {
      findGlModal().vm.$emit('secondary', mockEvent);
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('token')).toEqual([[]]);
      expect(mockEvent.preventDefault).toHaveBeenCalled();
    });

    it('should clear the project name input after generating the token', async () => {
      findProjectNameInput().vm.$emit('input', provide.projectName);
      findGlModal().vm.$emit('primary', mockEvent);
      await wrapper.vm.$nextTick();
      expect(findProjectNameInput().attributes('value')).toBe('');
    });

    it('should provide an input for filling the project name', () => {
      expect(findProjectNameInput().exists()).toBe(true);
      expect(findProjectNameInput().attributes('value')).toBe('');
    });

    it('should display an help text', () => {
      const help = wrapper.find('p');
      expect(help.text()).toMatch(/More Information/);
    });

    it('should have links to the documentation', () => {
      expect(wrapper.find('[data-testid="help-link"]').attributes('href')).toBe(
        provide.featureFlagsHelpPagePath,
      );
      expect(wrapper.find('[data-testid="help-client-link"]').attributes('href')).toBe(
        provide.featureFlagsClientLibrariesHelpPagePath,
      );
    });

    it('should display one and only one danger alert', () => {
      const dangerGlAlert = findDangerGlAlert();
      expect(dangerGlAlert.length).toBe(1);
      expect(dangerGlAlert.at(0).text()).toMatch(/Regenerating the instance ID/);
    });

    it('should display a message asking to fill the project name', () => {
      expect(wrapper.find('[data-testid="prevent-accident-text"]').text()).toMatch(
        provide.projectName,
      );
    });

    it('should display the api URL in an input box', () => {
      const input = wrapper.find('#api-url');
      expect(input.attributes('value')).toBe('/api/url');
    });

    it('should display the instance ID in an input box', () => {
      const input = wrapper.find('#instance_id');
      expect(input.attributes('value')).toBe('instance-id-token');
    });
  });

  describe('verified', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory);

    it('should enable the secondary action', async () => {
      findProjectNameInput().vm.$emit('input', provide.projectName);
      await wrapper.vm.$nextTick();
      const [{ disabled }] = findSecondaryAction().attributes;
      expect(disabled).toBe(false);
    });
  });

  describe('cannot rotate token', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { canUserRotateToken: false }));

    it('should not display the primary action', () => {
      expect(findSecondaryAction()).toBe(null);
    });

    it('should not display regenerating instance ID', async () => {
      expect(findDangerGlAlert().exists()).toBe(false);
    });

    it('should disable the project name input', async () => {
      expect(findProjectNameInput().exists()).toBe(false);
    });
  });

  describe('has rotate error', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { hasRotateError: false }));

    it('should display an error', async () => {
      expect(wrapper.find('.text-danger')).toExist();
      expect(wrapper.find('[name="warning"]')).toExist();
    });
  });

  describe('is rotating', () => {
    afterEach(() => wrapper.destroy());
    beforeEach(factory.bind(null, { isRotating: true }));

    it('should disable the project name input', async () => {
      expect(findProjectNameInput().attributes('disabled')).toBeTruthy();
    });
  });
});
