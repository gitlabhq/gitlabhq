import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiEditorHeader from '~/pipeline_editor/components/editor/ci_editor_header.vue';
import {
  pipelineEditorTrackingOptions,
  TEMPLATE_REPOSITORY_URL,
} from '~/pipeline_editor/constants';

describe('CI Editor Header', () => {
  let wrapper;
  let trackingSpy = null;

  const createComponent = ({ showDrawer = false } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CiEditorHeader, {
        propsData: {
          showDrawer,
        },
      }),
    );
  };

  const findLinkBtn = () => wrapper.findByTestId('template-repo-link');
  const findHelpBtn = () => wrapper.findByTestId('drawer-toggle');

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  describe('link button', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('finds the browse template button', () => {
      expect(findLinkBtn().exists()).toBe(true);
    });

    it('contains the link to the template repo', () => {
      expect(findLinkBtn().attributes('href')).toBe(TEMPLATE_REPOSITORY_URL);
    });

    it('has the external-link icon', () => {
      expect(findLinkBtn().props('icon')).toBe('external-link');
    });

    it('tracks the click on the browse button', async () => {
      const { label, actions } = pipelineEditorTrackingOptions;

      await findLinkBtn().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, actions.browse_templates, {
        label,
      });
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
      it('emits open drawer event when clicked', () => {
        createComponent({ showDrawer: false });

        expect(wrapper.emitted('open-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('open-drawer')).toHaveLength(1);
      });
    });

    describe('when pipeline editor drawer is open', () => {
      it('emits close drawer event when clicked', () => {
        createComponent({ showDrawer: true });

        expect(wrapper.emitted('close-drawer')).toBeUndefined();

        findHelpBtn().vm.$emit('click');

        expect(wrapper.emitted('close-drawer')).toHaveLength(1);
      });
    });
  });
});
