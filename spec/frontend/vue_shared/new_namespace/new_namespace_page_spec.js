import { GlBreadcrumb, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LegacyContainer from '~/vue_shared/new_namespace/components/legacy_container.vue';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { sidebarState } from '~/super_sidebar/constants';

jest.mock('~/super_sidebar/constants');
describe('Experimental new namespace creation app', () => {
  let wrapper;

  const findWelcomePage = () => wrapper.findComponent(WelcomePage);
  const findLegacyContainer = () => wrapper.findComponent(LegacyContainer);
  const findTopBar = () => wrapper.findByTestId('top-bar');
  const findBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);
  const findImage = () => wrapper.find('img');
  const findNewTopLevelGroupAlert = () => wrapper.findComponent(NewTopLevelGroupAlert);
  const findSuperSidebarToggle = () => wrapper.findComponent(SuperSidebarToggle);
  const findAccountVerificationAlert = () => wrapper.findComponent(GlAlert);

  const DEFAULT_PROPS = {
    title: 'Create something',
    initialBreadcrumbs: [{ text: 'Something', href: '#' }],
    panels: [
      { name: 'panel1', selector: '#some-selector1', imageSrc: 'panel1.svg' },
      { name: 'panel2', selector: '#some-selector2', imageSrc: 'panel2.svg' },
    ],
    persistenceKey: 'DEMO-PERSISTENCE-KEY',
  };

  const createComponent = ({ slots, propsData, identityVerificationRequired = false } = {}) => {
    wrapper = shallowMountExtended(NewNamespacePage, {
      slots,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      provide: {
        identityVerificationRequired,
        identityVerificationPath: '#',
      },
    });
  };

  afterEach(() => {
    window.location.hash = '';
  });

  describe('with empty hash', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders welcome page', () => {
      expect(findWelcomePage().exists()).toBe(true);
    });

    it('renders breadcrumbs', () => {
      expect(findBreadcrumb().exists()).toBe(true);
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
      expect(breadcrumb.props().items[0].text).toBe(DEFAULT_PROPS.initialBreadcrumbs[0].text);
    });

    it('renders images', () => {
      expect(findImage().element.src).toBe(DEFAULT_PROPS.panels[1].imageSrc);
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
    window.dispatchEvent(new Event('hashchange'));

    await nextTick();
    expect(findWelcomePage().exists()).toBe(false);
    expect(findLegacyContainer().exists()).toBe(true);
  });

  describe('SuperSidebarToggle', () => {
    describe('when collapsed', () => {
      it('shows sidebar toggle', () => {
        sidebarState.isCollapsed = true;
        createComponent();

        expect(findSuperSidebarToggle().exists()).toBe(true);
      });
    });

    describe('when not collapsed', () => {
      it('does not show sidebar toggle', () => {
        sidebarState.isCollapsed = false;
        createComponent();

        expect(findSuperSidebarToggle().exists()).toBe(false);
      });
    });
  });

  describe('top level group alert', () => {
    beforeEach(() => {
      window.location.hash = `#${DEFAULT_PROPS.panels[0].name}`;
    });

    describe('when self-managed', () => {
      it('does not render alert', () => {
        createComponent();

        expect(findNewTopLevelGroupAlert().exists()).toBe(false);
      });
    });

    describe('when on .com', () => {
      it('does not render alert', () => {
        createComponent({ propsData: { isSaas: true } });

        expect(findNewTopLevelGroupAlert().exists()).toBe(false);
      });

      describe('when empty parent group name', () => {
        it('renders alert', () => {
          createComponent({
            propsData: {
              isSaas: true,
              panels: [{ ...DEFAULT_PROPS.panels[0], detailProps: { parentGroupName: '' } }],
            },
          });

          expect(findNewTopLevelGroupAlert().exists()).toBe(true);
        });
      });
    });
  });

  describe('top bar', () => {
    it('has "top-bar-fixed" and "container-fluid" classes', () => {
      createComponent();

      expect(findTopBar().classes()).toEqual(['top-bar-fixed', 'container-fluid']);
    });
  });

  describe('account verification alert', () => {
    describe('when identity verification is not required', () => {
      beforeEach(() => {
        window.location.hash = 'panel1';
        createComponent({ identityVerificationRequired: false });
      });

      it('does not show account verification alert', () => {
        expect(findAccountVerificationAlert().exists()).toBe(false);
      });

      it('shows the group create form', () => {
        expect(findLegacyContainer().exists()).toBe(true);
      });
    });

    describe('when identity verification is required', () => {
      beforeEach(() => {
        window.location.hash = 'panel1';
        createComponent({ identityVerificationRequired: true });
      });

      it('shows the account verification alert', () => {
        expect(findAccountVerificationAlert().props()).toMatchObject({
          title: 'Before you can create additional groups, we need to verify your account.',
          dismissible: false,
          variant: 'danger',
          primaryButtonText: 'Verify my account',
          primaryButtonLink: '#',
        });

        expect(findAccountVerificationAlert().text()).toBe(
          `We won't ask you for this information again. It will never be used for marketing purposes.`,
        );
      });

      it('does not show the group create form', () => {
        expect(findLegacyContainer().exists()).toBe(false);
      });
    });
  });
});
