import { shallowMount } from '@vue/test-utils';
import { GlBreadcrumb } from '@gitlab/ui';
import App from '~/projects/experiment_new_project_creation/components/app.vue';
import WelcomePage from '~/projects/experiment_new_project_creation/components/welcome.vue';
import LegacyContainer from '~/projects/experiment_new_project_creation/components/legacy_container.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const createComponent = propsData => {
    wrapper = shallowMount(App, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
    wrapper = null;
  });

  describe('with empty hash', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders welcome page', () => {
      expect(wrapper.find(WelcomePage).exists()).toBe(true);
    });

    it('does not render breadcrumbs', () => {
      expect(wrapper.find(GlBreadcrumb).exists()).toBe(false);
    });
  });

  it('renders blank project container if there are errors', () => {
    createComponent({ hasErrors: true });
    expect(wrapper.find(WelcomePage).exists()).toBe(false);
    expect(wrapper.find(LegacyContainer).exists()).toBe(true);
  });

  describe('when hash is not empty on load', () => {
    beforeEach(() => {
      window.location.hash = '#blank_project';
      createComponent();
    });

    it('renders relevant container', () => {
      expect(wrapper.find(WelcomePage).exists()).toBe(false);
      expect(wrapper.find(LegacyContainer).exists()).toBe(true);
    });

    it('renders breadcrumbs', () => {
      expect(wrapper.find(GlBreadcrumb).exists()).toBe(true);
    });
  });

  describe('display custom new project guideline text', () => {
    beforeEach(() => {
      window.location.hash = '#blank_project';
    });

    it('does not render new project guideline if undefined', () => {
      createComponent();
      expect(wrapper.find('div#new-project-guideline').exists()).toBe(false);
    });

    it('render new project guideline if defined', () => {
      const guidelineSelector = 'div#new-project-guideline';

      createComponent({
        newProjectGuidelines: '<h4>Internal Guidelines</h4><p>lorem ipsum</p>',
      });
      expect(wrapper.find(guidelineSelector).exists()).toBe(true);
      expect(wrapper.find(guidelineSelector).html()).toContain('<h4>Internal Guidelines</h4>');
      expect(wrapper.find(guidelineSelector).html()).toContain('<p>lorem ipsum</p>');
    });
  });

  it('renders relevant container when hash changes', () => {
    createComponent();
    expect(wrapper.find(WelcomePage).exists()).toBe(true);

    window.location.hash = '#blank_project';
    const ev = document.createEvent('HTMLEvents');
    ev.initEvent('hashchange', false, false);
    window.dispatchEvent(ev);

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find(WelcomePage).exists()).toBe(false);
      expect(wrapper.find(LegacyContainer).exists()).toBe(true);
    });
  });
});
