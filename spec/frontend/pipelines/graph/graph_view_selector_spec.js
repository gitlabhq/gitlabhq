import { GlAlert, GlLoadingIcon, GlSegmentedControl } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { LAYER_VIEW, STAGE_VIEW } from '~/pipelines/components/graph/constants';
import GraphViewSelector from '~/pipelines/components/graph/graph_view_selector.vue';

describe('the graph view selector component', () => {
  let wrapper;

  const findDependenciesToggle = () => wrapper.find('[data-testid="show-links-toggle"]');
  const findViewTypeSelector = () => wrapper.findComponent(GlSegmentedControl);
  const findStageViewLabel = () => findViewTypeSelector().findAll('label').at(0);
  const findLayersViewLabel = () => findViewTypeSelector().findAll('label').at(1);
  const findSwitcherLoader = () => wrapper.find('[data-testid="switcher-loading-state"]');
  const findToggleLoader = () => findDependenciesToggle().find(GlLoadingIcon);
  const findHoverTip = () => wrapper.findComponent(GlAlert);

  const defaultProps = {
    showLinks: false,
    tipPreviouslyDismissed: false,
    type: STAGE_VIEW,
  };

  const defaultData = {
    hoverTipDismissed: false,
    isToggleLoading: false,
    isSwitcherLoading: false,
    showLinksActive: false,
  };

  const createComponent = ({ data = {}, mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(GraphViewSelector, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return {
          ...defaultData,
          ...data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when showing stage view', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it('shows the Stage view label as active in the selector', () => {
      expect(findStageViewLabel().classes()).toContain('active');
    });

    it('does not show the Job dependencies (links) toggle', () => {
      expect(findDependenciesToggle().exists()).toBe(false);
    });
  });

  describe('when showing Job dependencies view', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mount,
        props: {
          type: LAYER_VIEW,
        },
      });
    });

    it('shows the Job dependencies view label as active in the selector', () => {
      expect(findLayersViewLabel().classes()).toContain('active');
    });

    it('shows the Job dependencies (links) toggle', () => {
      expect(findDependenciesToggle().exists()).toBe(true);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      createComponent({
        mountFn: mount,
        props: {
          type: LAYER_VIEW,
        },
      });
    });

    it('shows loading state and emits updateViewType when view type toggled', async () => {
      expect(wrapper.emitted().updateViewType).toBeUndefined();
      expect(findSwitcherLoader().exists()).toBe(false);

      await findStageViewLabel().trigger('click');
      /*
        Loading happens before the event is emitted or timers are run.
        Then we run the timer because the event is emitted in setInterval
        which is what gives the loader a chace to show up.
      */
      expect(findSwitcherLoader().exists()).toBe(true);
      jest.runOnlyPendingTimers();

      expect(wrapper.emitted().updateViewType).toHaveLength(1);
      expect(wrapper.emitted().updateViewType).toEqual([[STAGE_VIEW]]);
    });

    it('shows loading state and emits updateShowLinks when show links toggle is clicked', async () => {
      expect(wrapper.emitted().updateShowLinksState).toBeUndefined();
      expect(findToggleLoader().exists()).toBe(false);

      await findDependenciesToggle().trigger('click');
      /*
        Loading happens before the event is emitted or timers are run.
        Then we run the timer because the event is emitted in setInterval
        which is what gives the loader a chace to show up.
      */
      expect(findToggleLoader().exists()).toBe(true);
      jest.runOnlyPendingTimers();

      expect(wrapper.emitted().updateShowLinksState).toHaveLength(1);
      expect(wrapper.emitted().updateShowLinksState).toEqual([[true]]);
    });
  });

  describe('hover tip callout', () => {
    describe('when links are live and it has not been previously dismissed', () => {
      beforeEach(() => {
        createComponent({
          props: {
            showLinks: true,
          },
          data: {
            showLinksActive: true,
          },
          mountFn: mount,
        });
      });

      it('is displayed', () => {
        expect(findHoverTip().exists()).toBe(true);
        expect(findHoverTip().text()).toBe(wrapper.vm.$options.i18n.hoverTipText);
      });

      it('emits dismissHoverTip event when the tip is dismissed', async () => {
        expect(wrapper.emitted().dismissHoverTip).toBeUndefined();
        await findHoverTip().find('button').trigger('click');
        expect(wrapper.emitted().dismissHoverTip).toHaveLength(1);
      });
    });

    describe('when links are live and it has been previously dismissed', () => {
      beforeEach(() => {
        createComponent({
          props: {
            showLinks: true,
            tipPreviouslyDismissed: true,
          },
          data: {
            showLinksActive: true,
          },
        });
      });

      it('is not displayed', () => {
        expect(findHoverTip().exists()).toBe(false);
      });
    });

    describe('when links are not live', () => {
      beforeEach(() => {
        createComponent({
          props: {
            showLinks: true,
          },
          data: {
            showLinksActive: false,
          },
        });
      });

      it('is not displayed', () => {
        expect(findHoverTip().exists()).toBe(false);
      });
    });
  });
});
