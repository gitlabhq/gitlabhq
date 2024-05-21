import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiEditorHeader from '~/ci/pipeline_editor/components/editor/ci_editor_header.vue';
import {
  pipelineEditorTrackingOptions,
  EDITOR_APP_DRAWER_HELP,
  EDITOR_APP_DRAWER_NONE,
} from '~/ci/pipeline_editor/constants';

describe('CI Editor Header', () => {
  let wrapper;
  let trackingSpy = null;

  const createComponent = ({
    showHelpDrawer = false,
    showJobAssistantDrawer = false,
    aiChatAvailable = false,
    aiCiConfigGenerator = false,
    ciCatalogPath = '/explore/catalog',
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CiEditorHeader, {
        provide: {
          aiChatAvailable,
          ciCatalogPath,
          glFeatures: {
            aiCiConfigGenerator,
          },
        },
        propsData: {
          showHelpDrawer,
          showJobAssistantDrawer,
        },
      }),
    );
  };

  const findHelpBtn = () => wrapper.findByTestId('drawer-toggle');
  const findCatalogRepoLinkButton = () => wrapper.findByTestId('catalog-repo-link');

  afterEach(() => {
    unmockTracking();
  });

  const testTracker = async (element, expectedAction) => {
    const { label } = pipelineEditorTrackingOptions;

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    await element.vm.$emit('click');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, expectedAction, {
      label,
    });
  };

  describe('component repo link button', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('finds the CI/CD Catalog button', () => {
      expect(findCatalogRepoLinkButton().exists()).toBe(true);
    });

    it('tracks the click on the Catalog button', () => {
      const { browseCatalog } = pipelineEditorTrackingOptions.actions;

      testTracker(findCatalogRepoLinkButton(), browseCatalog);
    });
  });

  describe('help button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds the help button', () => {
      expect(findHelpBtn().exists()).toBe(true);
    });

    it('has the information-o icon', () => {
      expect(findHelpBtn().props('icon')).toBe('information-o');
    });

    describe('when pipeline editor drawer is closed', () => {
      beforeEach(() => {
        createComponent({ showHelpDrawer: false });
      });

      it('emits switch drawer event when clicked', () => {
        expect(wrapper.emitted('switch-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('switch-drawer')).toEqual([[EDITOR_APP_DRAWER_HELP]]);
      });

      it('tracks open help drawer action', () => {
        const { actions } = pipelineEditorTrackingOptions;

        testTracker(findHelpBtn(), actions.openHelpDrawer);
      });
    });

    describe('when pipeline editor drawer is open', () => {
      beforeEach(() => {
        createComponent({ showHelpDrawer: true });
      });

      it('emits close drawer event when clicked', () => {
        expect(wrapper.emitted('switch-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('switch-drawer')).toEqual([[EDITOR_APP_DRAWER_NONE]]);
      });
    });
  });
});
