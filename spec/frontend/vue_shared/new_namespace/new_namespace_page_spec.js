import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LegacyContainer from '~/vue_shared/new_namespace/components/legacy_container.vue';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const findWelcomePage = () => wrapper.findComponent(WelcomePage);
  const findLegacyContainer = () => wrapper.findComponent(LegacyContainer);
  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  const DEFAULT_PROPS = {
    title: 'Create something',
    initialBreadcrumb: 'Something',
    panels: [
      { name: 'panel1', selector: '#some-selector1' },
      { name: 'panel2', selector: '#some-selector2' },
    ],
    persistenceKey: 'DEMO-PERSISTENCE-KEY',
  };

  const createComponent = ({ slots, propsData } = {}) => {
    wrapper = shallowMount(NewNamespacePage, {
      slots,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    window.location.hash = '';
  });

  describe('with empty hash', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders welcome page', () => {
      expect(findWelcomePage().exists()).toBe(true);
    });

    it('does not render breadcrumbs', () => {
      expect(findBreadcrumb().exists()).toBe(false);
    });
  });

  it('renders first container if jumpToLastPersistedPanel passed', () => {
    createComponent({ propsData: { jumpToLastPersistedPanel: true } });
    expect(findWelcomePage().exists()).toBe(false);
    expect(findLegacyContainer().exists()).toBe(true);
  });

  describe('when hash is not empty on load', () => {
    beforeEach(() => {
      window.location.hash = `#${DEFAULT_PROPS.panels[1].name}`;
      createComponent();
    });

    it('renders relevant container', () => {
      expect(findWelcomePage().exists()).toBe(false);

      const container = findLegacyContainer();

      expect(container.exists()).toBe(true);
      expect(container.props().selector).toBe(DEFAULT_PROPS.panels[1].selector);
    });

    it('renders breadcrumbs', () => {
      const breadcrumb = findBreadcrumb();
      expect(breadcrumb.exists()).toBe(true);
      expect(breadcrumb.props().items[0].text).toBe(DEFAULT_PROPS.initialBreadcrumb);
    });
  });

  it('renders extra description if provided', () => {
    window.location.hash = `#${DEFAULT_PROPS.panels[1].name}`;
    const EXTRA_DESCRIPTION = 'Some extra description';
    createComponent({
      slots: {
        'extra-description': EXTRA_DESCRIPTION,
      },
    });

    expect(wrapper.text()).toContain(EXTRA_DESCRIPTION);
  });

  it('renders relevant container when hash changes', async () => {
    createComponent();
    expect(findWelcomePage().exists()).toBe(true);

    window.location.hash = `#${DEFAULT_PROPS.panels[0].name}`;
    const ev = document.createEvent('HTMLEvents');
    ev.initEvent('hashchange', false, false);
    window.dispatchEvent(ev);

    await nextTick();
    expect(findWelcomePage().exists()).toBe(false);
    expect(findLegacyContainer().exists()).toBe(true);
  });
});
