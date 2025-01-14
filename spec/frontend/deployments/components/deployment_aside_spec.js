import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { nextTick } from 'vue';
import mockDeploymentFixture from 'test_fixtures/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import mockEnvironmentFixture from 'test_fixtures/graphql/deployments/graphql/queries/environment.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ShowMore from '~/vue_shared/components/show_more.vue';
import DeploymentAside from '~/deployments/components/deployment_aside.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { CLICK_PIPELINE_LINK_ON_DEPLOYMENT_PAGE } from '~/deployments/utils';

const {
  data: {
    project: { deployment },
  },
} = mockDeploymentFixture;
const {
  data: {
    project: { environment },
  },
} = mockEnvironmentFixture;
const { bindInternalEventDocument } = useMockInternalEventsTracking();

describe('~/deployments/components/deployment_aside.vue', () => {
  let wrapper;

  const findSidebarToggleButton = () => wrapper.findByTestId('deployment-sidebar-toggle-button');
  const findSidebar = () => wrapper.findByTestId('deployment-sidebar');
  const findSidebarItems = () => wrapper.findByTestId('deployment-sidebar-items');
  const findUrlButtonWrapper = () => wrapper.findByTestId('deployment-url-button-wrapper');
  const findTriggererItem = () => wrapper.findByTestId('deployment-triggerer-item');
  const findPipelineSection = () => wrapper.findByTestId('deployment-pipeline');
  const findPipelineLink = () => wrapper.findByTestId('deployment-pipeline-link');

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(DeploymentAside, {
      propsData: {
        deployment,
        environment,
        loading: false,
        ...propsData,
      },
    });
  };

  describe('loading', () => {
    it('hides everything', () => {
      createComponent({ propsData: { loading: true } });

      expect(wrapper.find('aside').exists()).toBe(false);
    });
  });

  describe('with all properties', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a link to the external url', () => {
      const link = wrapper.findByRole('link', { name: 'Open URL' });

      expect(link.attributes('href')).toBe(environment.externalUrl);
    });

    it('shows a link to the triggerer', () => {
      const link = wrapper.findByTestId('deployment-triggerer');

      expect(link.attributes('href')).toBe(deployment.triggerer.webUrl);
      expect(link.text()).toContain(deployment.triggerer.name);
    });

    it('shows a section with a link to the Pipeline', () => {
      expect(findPipelineSection().exists()).toBe(true);
      expect(findPipelineSection().text()).toContain('Pipeline');

      expect(findPipelineLink().exists()).toBe(true);
      expect(findPipelineLink().attributes('href')).toBe(deployment.job.pipeline.path);
      expect(findPipelineLink().text()).toBe(`#${getIdFromGraphQLId(deployment.job.pipeline.id)}`);
    });

    it('should call trackEvent method when pipeline link is clicked', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findPipelineLink().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledTimes(1);
      expect(trackEventSpy).toHaveBeenCalledWith(
        CLICK_PIPELINE_LINK_ON_DEPLOYMENT_PAGE,
        {},
        undefined,
      );
    });

    it('shows a link to the tags of a deployment', () => {
      deployment.tags.forEach((tag) => {
        const link = wrapper.findByRole('link', { name: tag.name });

        expect(link.attributes('href')).toBe(tag.webPath);
      });
    });

    it('links to the deployment ref', () => {
      const link = wrapper.findByRole('link', { name: deployment.ref });

      expect(link.attributes('href')).toBe(deployment.refPath);
    });

    it('displays if the ref is a branch', () => {
      const ref = wrapper.findByTestId('deployment-ref');

      expect(ref.find('span').text()).toBe('Branch');
    });
  });

  describe('without optional properties', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            tags: [],
            job: null,
            tag: true,
          },
          environment: {
            ...environment,
            externalUrl: '',
          },
        },
      });
    });

    it('does not show a link to the external url', () => {
      const link = wrapper.findByRole('link', { name: 'Open URL' });

      expect(link.exists()).toBe(false);
    });

    it('does not show a link to the tags of a deployment', () => {
      const showMore = wrapper.findComponent(ShowMore);

      expect(showMore.exists()).toBe(false);
    });

    it('displays if the ref is a branch', () => {
      const ref = wrapper.findByTestId('deployment-ref');

      expect(ref.find('span').text()).toBe('Tag');
    });
  });

  describe('toggle button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is exist', () => {
      const button = findSidebarToggleButton();

      expect(button.exists()).toBe(true);
      expect(button.classes()).toContain('lg:gl-hidden');
    });

    describe('on mobile', () => {
      describe('when the sidebar is collapsed', () => {
        beforeEach(() => {
          jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

          createComponent();
        });

        it('has correct attributes', () => {
          const button = findSidebarToggleButton();

          expect(button.attributes('title')).toBe('Expand sidebar');
          expect(button.attributes('aria-label')).toBe('Expand sidebar');
          expect(button.props('category')).toBe('secondary');
          expect(wrapper.findByTestId('chevron-double-lg-left-icon').isVisible()).toBe(true);
        });

        it('expands the sidebar on click', async () => {
          let sidebarItems = findSidebarItems();

          expect(sidebarItems.exists()).toBe(false);

          const button = findSidebarToggleButton();
          button.trigger('click');
          await nextTick();

          sidebarItems = findSidebarItems();

          expect(sidebarItems.exists()).toBe(true);
        });
      });

      describe('when the sidebar is expanded', () => {
        let button;

        beforeEach(async () => {
          jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

          createComponent();

          button = findSidebarToggleButton();
          button.trigger('click');
          await nextTick();
        });

        it('has correct attributes', () => {
          expect(button.attributes('title')).toBe('Collapse sidebar');
          expect(button.attributes('aria-label')).toBe('Collapse sidebar');
          expect(button.props('category')).toBe('tertiary');
          expect(wrapper.findByTestId('chevron-double-lg-right-icon').isVisible()).toBe(true);
        });

        it('collapses the sidebar on click', async () => {
          button.trigger('click');
          await nextTick();

          const sidebarItems = findSidebarItems();

          expect(sidebarItems.exists()).toBe(false);
        });
      });
    });
  });

  describe('sidebar', () => {
    describe('on desktop', () => {
      it('has correct CSS classes', () => {
        createComponent();

        const sidebarItems = findSidebar();

        expect(sidebarItems.classes()).not.toContain('right-sidebar');
        expect(sidebarItems.classes()).not.toContain('right-sidebar-expanded');
        expect(sidebarItems.classes()).not.toContain('gl-shadow-md');
        expect(sidebarItems.classes()).not.toContain('gl-fixed');
        expect(sidebarItems.classes()).not.toContain('gl-right-0');
      });
    });

    describe('on mobile', () => {
      let button;

      beforeEach(async () => {
        jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

        createComponent();

        button = findSidebarToggleButton();
        button.trigger('click');
        await nextTick();
      });

      describe('when the sidebar is expanded', () => {
        it('has correct CSS classes', () => {
          const sidebarItems = findSidebar();

          expect(sidebarItems.classes()).toContain('right-sidebar');
          expect(sidebarItems.classes()).toContain('right-sidebar-expanded');
          expect(sidebarItems.classes()).toContain('gl-shadow-md');
          expect(sidebarItems.classes()).not.toContain('gl-fixed');
          expect(sidebarItems.classes()).not.toContain('gl-right-0');
        });
      });

      describe('when the sidebar is collapsed', () => {
        it('has correct CSS classes', async () => {
          button.trigger('click');
          await nextTick();

          const sidebarItems = findSidebar();

          expect(sidebarItems.classes()).not.toContain('right-sidebar');
          expect(sidebarItems.classes()).not.toContain('right-sidebar-expanded');
          expect(sidebarItems.classes()).not.toContain('gl-shadow-md');
          expect(sidebarItems.classes()).toContain('gl-fixed');
          expect(sidebarItems.classes()).toContain('gl-right-0');
        });
      });
    });
  });

  describe('sidebar items', () => {
    describe('on desktop', () => {
      beforeEach(() => {
        createComponent();
      });

      it('shows the sidebar items', () => {
        const sidebarItems = findSidebarItems();

        expect(sidebarItems.exists()).toBe(true);
      });

      it('does not have CSS classes', () => {
        const sidebarItems = findSidebarItems();

        expect(sidebarItems.classes()).not.toContain('gl-border-t-1');
        expect(sidebarItems.classes()).not.toContain('gl-mt-5');
        expect(sidebarItems.classes()).not.toContain('gl-border-default');
        expect(sidebarItems.classes()).not.toContain('gl-border-t-solid');
      });
    });

    describe('on mobile', () => {
      beforeEach(() => {
        jest.spyOn(bp, 'isDesktop').mockReturnValue(false);
      });

      it('hides the sidebar items by default', () => {
        createComponent();

        const sidebarItems = findSidebarItems();

        expect(sidebarItems.exists()).toBe(false);
      });

      it('has correct CSS classes when the sidebar is expanded', async () => {
        createComponent();

        const button = findSidebarToggleButton();
        button.trigger('click');
        await nextTick();

        const sidebarItems = findSidebarItems();

        expect(sidebarItems.classes()).toContain('gl-border-t');
        expect(sidebarItems.classes()).toContain('gl-mt-5');
      });
    });
  });

  describe('url button wrapper', () => {
    describe('on desktop', () => {
      it('does not have CSS classes', () => {
        createComponent();

        const urlButtonWrapper = findUrlButtonWrapper();

        expect(urlButtonWrapper.classes()).not.toContain('gl-mt-5');
        expect(urlButtonWrapper.classes()).not.toContain('gl-border-b-1');
        expect(urlButtonWrapper.classes()).not.toContain('gl-border-default');
        expect(urlButtonWrapper.classes()).not.toContain('gl-pb-5');
        expect(urlButtonWrapper.classes()).not.toContain('gl-border-b-solid');
      });
    });

    describe('on mobile', () => {
      it('has correct CSS classes', async () => {
        jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

        createComponent();

        const button = findSidebarToggleButton();
        button.trigger('click');
        await nextTick();

        const urlButtonWrapper = findUrlButtonWrapper();

        expect(urlButtonWrapper.classes()).toContain('gl-mt-5');
        expect(urlButtonWrapper.classes()).toContain('gl-border-b');
        expect(urlButtonWrapper.classes()).toContain('gl-pb-5');
      });
    });
  });

  describe('triggerer item', () => {
    describe('on desktop', () => {
      it('has correct CSS classes', () => {
        createComponent();

        const triggererItem = findTriggererItem();

        expect(triggererItem.classes()).toContain('gl-mt-8');
        expect(triggererItem.classes()).toContain('gl-border-subtle');
        expect(triggererItem.classes()).toContain('gl-border-b');
        expect(triggererItem.classes()).not.toContain('gl-mt-5');
      });
    });

    describe('on mobile', () => {
      it('has correct CSS classes', async () => {
        jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

        createComponent();

        const button = findSidebarToggleButton();
        button.trigger('click');
        await nextTick();

        const triggererItem = findTriggererItem();

        expect(triggererItem.classes()).toContain('gl-mt-5');
        expect(triggererItem.classes()).toContain('gl-border-b');
        expect(triggererItem.classes()).not.toContain('gl-mt-8');
        expect(triggererItem.classes()).not.toContain('gl-border-subtle');
      });
    });
  });

  describe('on window resize after transition from mobile to desktop', () => {
    beforeEach(() => {
      jest.spyOn(bp, 'isDesktop').mockReturnValue(false);

      createComponent();
    });

    it('the sidebar is visible', async () => {
      let sidebarItems = findSidebarItems();

      expect(sidebarItems.exists()).toBe(false);

      jest.spyOn(bp, 'isDesktop').mockReturnValue(true);
      window.dispatchEvent(new Event('resize'));
      await nextTick();

      sidebarItems = findSidebarItems();

      expect(sidebarItems.exists()).toBe(true);
    });
  });
});
